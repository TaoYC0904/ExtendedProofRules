Require Import Shallow.Imp.
Require Import Shallow.ImpCF.
Require Import Shallow.Embeddings.

Import Assertion_Shallow.
Import BigS.

Definition SP (P : Assertion) (c : com) (st : state): Prop :=
  exists st0, Assertion_denote st0 P /\ ceval c st0 EK_Normal st.
  
Lemma same_def_bigstep : forall P c Q R1 R2,
  total_valid_bigstep P c Q R1 R2 <->
    (forall st1 : state, Assertion_denote st1 P ->
      (exists (ek : exit_kind) (st2 : state), ceval c st1 ek st2) /\
      (forall st2 ek, ceval c st1 ek st2 ->
        (ek = EK_Normal -> Assertion_denote st2 Q) /\
        (ek = EK_Break -> Assertion_denote st2 R1) /\ 
        (ek = EK_Cont -> Assertion_denote st2 R2))).
Proof.
  unfold iff.
  split.
  { intros.
    unfold total_valid_bigstep in H.
    destruct H.
    unfold partial_valid_bigstep in H1.
    split.
    + specialize (H st1 H0).
      tauto.
    + intros.
      specialize (H1 st1 st2 ek H0 H2).
      tauto. }
  { intros.
    unfold total_valid_bigstep.
    unfold partial_valid_bigstep.
    split.
    + intros.
      specialize (H st1 H0).
      destruct H.
      tauto.
    + intros.
      specialize (H st1 H0).
      destruct H.
      specialize (H2 st2 ek H1).
      tauto. }
Qed.

Lemma seq_c1_valid : forall P c1 c2 Q R1 R2 Q',
  total_valid_bigstep P (CSeq c1 c2) Q R1 R2 ->
  Q' = SP P c1 ->
  total_valid_bigstep P c1 Q' R1 R2.
Proof.
  intros.
  unfold total_valid_bigstep in H.
  unfold total_valid_bigstep.
  destruct H.
  split.
  + (* terminate *)
    intros.
    specialize (H st1 H2).
    destruct H as [ek [st2 ?]].
    simpl in H; unfold seq_sem in H.
    destruct H.
    - (* c1 Normal *)
      destruct H as [st3 [? ?]].
      exists EK_Normal, st3; tauto.
    - (* c1 Break or Cont *)
      destruct H.
      exists ek, st2; tauto.
  + (* partial validity *)
    unfold partial_valid_bigstep in H1.
    unfold partial_valid_bigstep.
    intros.
    destruct ek.
    - (* c1 Normal *)
      split; try split; intros; inversion H4.
      subst Q'.
      unfold Assertion_denote, SP.
      exists st1; tauto.
    - (* c1 Break *)
      split; try split; intros; inversion H4.
      assert (ceval (CSeq c1 c2) st1 EK_Break st2).
      { simpl; unfold seq_sem.
        right.
        split; [tauto | unfold not; intros; inversion H5]. }
      specialize (H1 st1 st2 EK_Break H2 H5).
      destruct H1 as [? [? ?]].
      apply H6; tauto.
    - (* c1 Cont *)
      split; try split; intros; inversion H4.
      assert (ceval (CSeq c1 c2) st1 EK_Cont st2).
      { simpl; unfold seq_sem.
        right.
        split; [tauto | unfold not; intros; inversion H5]. }
      specialize (H1 st1 st2 EK_Cont H2 H5).
      destruct H1 as [? [? ?]].
      apply H7; tauto.
Qed.

Lemma seq_c2_valid : forall P c1 c2 Q R1 R2 Q',
  total_valid_bigstep P (CSeq c1 c2) Q R1 R2 ->
  Q' = SP P c1 ->
  total_valid_bigstep Q' c2 Q R1 R2.
Proof.
  intros.
  unfold total_valid_bigstep in H.
  destruct H.
  unfold total_valid_bigstep.
  split.
  2:{
    unfold partial_valid_bigstep in H1.
    unfold partial_valid_bigstep.
    intros.
    subst Q'.
    unfold Assertion_denote, SP in H2.
    destruct H2 as [st0 [? ?]].
    specialize (H1 st0 st2 ek H0).
    apply H1.
    simpl; unfold seq_sem.
    left.
    exists st1; tauto. }
  intros.
  subst.
  unfold Assertion_denote, SP in H2.
  destruct H2 as [st0 [? ?]].
  specialize (H st0 H0).
  destruct H as [ek [st2 ?]].
  exists ek, st2.
  simpl in H.
  unfold seq_sem in H.
  destruct H.
  + destruct H as [st3 [? ?]].
    pose proof determinism.
    specialize (H4 c1 st0 st1 st3 EK_Normal EK_Normal H2 H).
    destruct H4; subst; tauto.
  + destruct H.
    pose proof determinism.
    specialize (H4 c1 st0 st1 st2 EK_Normal ek H2 H).
    destruct H4; subst; tauto.
Qed.

Theorem seq_inv_valid_bigstep : forall P c1 c2 Q R1 R2,
  total_valid_bigstep P (CSeq c1 c2) Q R1 R2 ->
  (exists Q', (total_valid_bigstep P c1 Q' R1 R2) /\ 
    (total_valid_bigstep Q' c2 Q R1 R2)).
Proof.
  intros.
  remember (SP P c1) as Q'.
  exists Q'.
  pose proof seq_c1_valid.
  specialize (H0 P c1 c2 Q R1 R2 Q' H HeqQ').
  pose proof seq_c2_valid.
  specialize (H1 P c1 c2 Q R1 R2 Q' H HeqQ').
  tauto.
Qed.

Theorem if_seq_valid_bigstep : forall P b c1 c2 c3 Q R1 R2,
  total_valid_bigstep P (CSeq (CIf b c1 c2) c3) Q R1 R2 ->
  total_valid_bigstep P (CIf b (CSeq c1 c3) (CSeq c2 c3)) Q R1 R2.
Proof.
  unfold total_valid_bigstep.
  intros; destruct H; split.
  + (* Termination *)
    intros.
    specialize (H st1 H1).
    destruct H as [ek [st2 ?]].
    exists ek, st2.
    simpl in H; simpl.
    unfold seq_sem, if_sem in H.
    unfold if_sem.
    unfold union_sem.
    destruct H.
    - (* (If b Then c1 Else c2) Normal Exit *)
      destruct H as [st3 [? ?]].
      unfold union_sem in H.
      destruct H.
      * (* b = True *)
        left.
        unfold seq_sem in H.
        unfold seq_sem at 1.
        destruct H.
        ++ (* c1 Normal Exit *)
           left.
           destruct H as [st4 [? ?]].
           unfold test_sem in H.
           destruct H as [? [? ?]]; subst.
           unfold test_sem.
           exists st4.
           split; try tauto.
           unfold seq_sem; left.
           exists st3; tauto.
        ++ (* c1 Break or Cont *)
           tauto.
      * (* b = False *)
        right.
        unfold seq_sem in H.
        unfold seq_sem at 1.
        destruct H.
        ++ (* c2 Normal Exit *)
           left.
           destruct H as [st4 [? ?]].
           unfold test_sem in H.
           destruct H as [? [? ?]]; subst.
           unfold test_sem.
           exists st4.
           split; try tauto.
           unfold seq_sem; left.
           exists st3; tauto.
        ++ tauto.
    - (* (If b Then c1 Else c2) Break or Cont *)
      destruct H.
      unfold union_sem in H.
      destruct H.
      * (* b = True *)
        left.
        unfold seq_sem in H.
        unfold seq_sem.
        destruct H.
        ++ (* c1 Normal Exit *)
           left.
           destruct H as [st3 [? ?]].
           exists st3. tauto.
        ++ (* c1 Break or Cont *)
           right.
           tauto.
      * (* b = False *)
        right.
        unfold seq_sem in H.
        unfold seq_sem.
        destruct H.
        ++ (* c1 Normal Exit *)
           left.
           destruct H as [st3 [? ?]].
           exists st3. tauto.
        ++ (* c1 Break or Cont *)
           right.
           tauto.
  + (* partial validity *)
    unfold partial_valid_bigstep in H0.
    unfold partial_valid_bigstep.
    intros.
    specialize (H0 st1 st2 ek H1).
    apply H0.
    simpl in H2; simpl.
    unfold if_sem in H2.
    unfold union_sem in H2.
    unfold if_sem.
    unfold seq_sem at 1.
    destruct H2.
    - (* b = True *)
      unfold seq_sem at 1 in H2.
      destruct H2.
      * (* test Normal Exit *)
        destruct H2 as [st3 [? ?]].
        unfold test_sem in H2.
        destruct H2 as [? [? ?]]; subst.
        unfold seq_sem in H3.
        destruct H3.
        ++ (* c1 Normal Exit *)
           destruct H2 as [st4 [? ?]].
           left.
           exists st4.
           split; try tauto.
           unfold union_sem; left.
           unfold test_sem, seq_sem.
           left.
           exists st3.
           tauto.
        ++ (* c1 Break or Cont *)
           destruct H2.
           right.
           split; try tauto.
           unfold union_sem; left.
           unfold test_sem, seq_sem.
           left.
           exists st3.
           tauto.
      * (* test Break or Cont *)
        destruct H2.
        unfold test_sem in H2.
        tauto.
    - (* b = False *)
      unfold seq_sem at 1 in H2.
      destruct H2.
      * (* test Normal Exit *)
        destruct H2 as [st3 [? ?]].
        unfold test_sem in H2.
        destruct H2 as [? [? ?]]; subst.
        unfold seq_sem in H3.
        destruct H3.
        ++ (* c2 Normal Exit *)
           destruct H2 as [st4 [? ?]].
           left.
           exists st4.
           split; try tauto.
           unfold union_sem; right.
           unfold test_sem, seq_sem.
           left.
           exists st3.
           tauto.
        ++ (* c2 Break or Cont *)
           destruct H2.
           right.
           split; try tauto.
           unfold union_sem; right.
           unfold test_sem, seq_sem.
           left.
           exists st3.
           tauto.
        * (* test Break or Cont *)
          destruct H2.
          unfold test_sem in H2.
          tauto.
Qed.

Lemma nocontinue_nocontexit : forall c st1,
  nocontinue c ->
  ( (exists st2, ceval c st1 EK_Cont st2) -> False).
Proof.
  intros c.
  induction c; intros.
  + (* c = CSkip *)
    destruct H0 as [st2 ?].
    simpl in H0; unfold skip_sem in H0.
    destruct H0.
    inversion H1.
  + (* c = CAss X a *)
    destruct H0 as [st2 ?].
    simpl in H0; unfold asgn_sem in H0.
    destruct H0 as [? [? ?]].
    inversion H2.
  + (* c = CSeq c1 c2 *)
    destruct H0 as [st2 ?].
    simpl in H; destruct H.
    simpl in H0; unfold seq_sem in H0.
    destruct H0.
    - (* c1 Normal *)
      destruct H0 as [st3 [? ?]].
      specialize (IHc2 st3 H1).
      apply IHc2.
      exists st2; tauto.
    - (* c1 Break or Cont *)
      destruct H0.
      specialize (IHc1 st1 H).
      apply IHc1.
      exists st2; tauto.
  + (* c = CIf b c1 c2 *)
    destruct H0 as [st2 ?].
    simpl in H0; unfold if_sem in H0.
    unfold union_sem in H0.
    destruct H0.
    - (* b = True *)
      unfold seq_sem, test_sem in H0.
      destruct H0.
      * (* test Normal *)
        destruct H0 as [st3 [? ?]].
        destruct H0 as [? [? ?]]; subst.
        simpl in H; destruct H.
        specialize (IHc1 st3 H).
        apply IHc1.
        exists st2; tauto.
      * (* test Break or Cont *)
         destruct H0 as [[? [? ?]] ?].
         inversion H2.
     - (* b = False *)
        unfold seq_sem, test_sem in H0.
        destruct H0.
        * (* test Normal *)
          destruct H0 as [st3 [? ?]].
          destruct H0 as [? [? ?]]; subst.
          simpl in H; destruct H.
          specialize (IHc2 st3 H0).
          apply IHc2.
          exists st2; tauto.
        * (* test Break or Cont *)
          destruct H0 as [[? [? ?]] ?].
          inversion H2.
  + (* c = CFor c1 c2 *)
    destruct H0 as [st2 ?].
    simpl in H0.
    unfold for_sem in H0.
    destruct H0.
    inversion H0.
  + (* c = CBreak *)
    destruct H0 as [st2 ?].
    simpl in H0.
    unfold break_sem in H0.
    destruct H0.
    inversion H1.
  + (* c = CCont *)
    simpl in H.
    tauto.
Qed.

Theorem nocontinue_valid_bigstep : forall P c Q R1 R2 R2',
  nocontinue c ->
  total_valid_bigstep P c Q R1 R2 ->
  total_valid_bigstep P c Q R1 R2'.
Proof.
  intros.
  unfold total_valid_bigstep in H0.
  unfold total_valid_bigstep.
  destruct H0.
  split.
  2:{ unfold partial_valid_bigstep in H1.
      unfold partial_valid_bigstep.
      intros.
      specialize (H1 st1 st2 ek H2 H3).
      destruct H1 as [? [? ?]].
      split; try split; try tauto.
      intros; subst ek.
      pose proof nocontinue_nocontexit.
      specialize (H6 c st1 H).
      exfalso.
      apply H6.
      exists st2; tauto. }
  intros.
  specialize (H0 st1 H2).
  destruct H0 as [ek [st2 ?]].
  exists ek, st2; tauto.
Qed.


Lemma add_skip: forall d st1 ek st2,
  d st1 ek st2 <-> (seq_sem d skip_sem) st1 ek st2.
Proof.
  intros.
  unfold iff; split.
  + intros.
    unfold seq_sem.
    destruct ek.
    - left. exists st2.
      split; try tauto.
      unfold skip_sem.
      split; tauto.
    - right.
      split; try tauto.
      unfold not; intros; inversion H0.
    - right.
      split; try tauto.
      unfold not; intros; inversion H0.
  + intros.
    unfold seq_sem in H.
    destruct H.
    - destruct H as [st3 [? ?]].
      unfold skip_sem in H0.
      destruct H0; subst ek; subst st3.
      tauto.
    - tauto.
Qed.

Lemma loop_nocontinue_partial_valid : forall P c1 c2 Q R1 R2,
  nocontinue c1 ->
  nocontinue c2 ->
  partial_valid_bigstep P (CFor (CSeq c1 c2) CSkip) Q R1 R2 ->
  partial_valid_bigstep P (CFor c1 c2) Q R1 R2.
Proof.
  intros.
  unfold partial_valid_bigstep in H1.
  unfold partial_valid_bigstep.
  intros.
  specialize (H1 st1 st2 ek H2).
  apply H1; clear H1.
  simpl in H3; simpl.
  unfold for_sem in H3; unfold for_sem.
  destruct H3.
  split; try tauto.
  destruct H3 as [n ?].
  exists n.
  remember (ceval c1) as d1.
  remember (ceval c2) as d2.
  clear H2.
  revert st1 H3.
  induction n.
  2:{
    intros.
    pose proof ILB_n.
    inversion H3; subst.
    inversion H4; subst n'.
    specialize (H2 (seq_sem (ceval c1) (ceval c2)) skip_sem (S n) st1 st2 st4 n).
    apply H2; clear H2; try tauto.
    + destruct H5.
      { left.
        pose proof add_skip.
        specialize (H2 (seq_sem (ceval c1) (ceval c2)) st1 EK_Normal st4).
        tauto. }
      pose proof nocontinue_nocontexit.
      specialize (H2 (CSeq c1 c2) st1).
      exfalso; apply H2; clear H2.
      { simpl; tauto. }
      exists st4; simpl; tauto.
    + specialize (IHn st4).
      apply IHn.
      tauto. }
  intros.
  inversion H3; subst.
  { constructor.
    destruct H2.
    + left.
      unfold seq_sem.
      right; split; try tauto.
      unfold not; intros; inversion H2.
    + left.
      unfold seq_sem.
      left; tauto. }
  inversion H2.
Qed.

Theorem loop_nocontinue_valid_bigstep : forall P c1 c2 Q R1 R2,
  nocontinue c1 ->
  nocontinue c2 ->
  total_valid_bigstep P (CFor (CSeq c1 c2) CSkip) Q R1 R2 ->
  total_valid_bigstep P (CFor c1 c2) Q R1 R2.
Proof.
  intros.
  pose proof loop_nocontinue_partial_valid.
  unfold total_valid_bigstep in H1.
  unfold total_valid_bigstep.
  destruct H1.
  split.
  2:{ specialize (H2 P c1 c2 Q R1 R2 H H0 H3); tauto. }
  clear H2 H3.
  intros.
  specialize (H1 st1 H2).
  destruct H1 as [ek [st2 ?]].
  exists ek, st2.
  simpl in H1; simpl.
  unfold for_sem in H1; unfold for_sem.
  destruct H1; split; try tauto.
  destruct H3 as [n ?].
  exists n.
  clear H2.
  revert st1 H3.
  induction n.
  2:{
    intros.
    inversion H3; subst.
    inversion H2; subst n'.
    pose proof ILB_n.
    specialize (H1 (ceval c1) (ceval c2) (S n) st1 st2 st4 n).
    apply H1; try tauto; clear H1.
    + destruct H4.
      { left.
        pose proof add_skip.
        specialize (H4 (seq_sem (ceval c1) (ceval c2)) st1 EK_Normal st4).
        tauto. }
      pose proof nocontinue_nocontexit.
      specialize (H4 (CSeq c1 c2) st1).
      exfalso; apply H4; clear H4.
      { simpl; tauto. }
      exists st4; simpl.
      pose proof add_skip.
      specialize (H4 (seq_sem (ceval c1) (ceval c2)) st1 EK_Cont st4); tauto.
    + specialize (IHn st4); tauto. }
  intros.
  constructor.
  inversion H3; subst.
  { destruct H2.
    + unfold seq_sem in H1.
      destruct H1.
      - destruct H1 as [st3 [? ?]].
        right; exists st3; tauto.
      - destruct H1.
        left; tauto.
    + destruct H1 as [st3 [? ?]].
      unfold skip_sem in H2.
      destruct H2.
      inversion H4. }
  inversion H2.
Qed.
