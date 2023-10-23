import Mathlib

set_option autoImplicit false
set_option pp.proofs.withType false

open Set Interval

variable {a b c t : ℝ} {E : Type*} [TopologicalSpace E]

section real

variable {f g : ℝ → E}

noncomputable def glue_at (b : ℝ) (f g : ℝ → E) := λ t => if t ≤ b then f t else g t

lemma continuous_glue (hf : Continuous f) (hg : Continuous g) (h : f b = g b) :
    Continuous (glue_at b f g) :=
  hf.if_le hg continuous_id continuous_const (λ _ hx => hx.symm ▸ h)

end real

section Icc

variable {F : Icc a b → E} {G : Icc b c → E}

noncomputable def glue_Icc (F : Icc a b → E) (G : Icc b c → E) (t : Icc a c) : E :=
  if h : t ≤ b then F ⟨t, t.2.1, h⟩ else G ⟨t, not_le.1 h |>.le, t.2.2⟩

lemma glue_Icc_eq (hab : a ≤ b) (hbc : b ≤ c) :
    glue_Icc F G = λ t : Icc a c => if t ≤ b then IccExtend hab F t else IccExtend hbc G t := by
  ext t ; simp [glue_Icc] ; split_ifs <;> symm <;> apply IccExtend_of_mem

lemma continuous_glue_Icc (hF : Continuous F) (hG : Continuous G) (hab : a ≤ b) (hbc : b ≤ c)
    (h : F ⟨b, right_mem_Icc.2 hab⟩ = G ⟨b, left_mem_Icc.2 hbc⟩) :
    Continuous (glue_Icc F G) := by
  rw [glue_Icc_eq hab hbc]
  exact continuous_glue hF.Icc_extend' hG.Icc_extend' (by simpa) |>.comp continuous_subtype_val

noncomputable def ContinuousMap.trans (hab : a ≤ b) (hbc : b ≤ c) (F : C(Icc a b, E))
    (G : C(Icc b c, E)) (h : F ⟨b, right_mem_Icc.2 hab⟩ = G ⟨b, left_mem_Icc.2 hbc⟩) :
    C(Icc a c, E) where
  toFun := glue_Icc F G
  continuous_toFun := continuous_glue_Icc F.continuous G.continuous hab hbc h

end Icc

section uIcc

variable {F : Icc a b → E} {G : uIcc b c → E}

open Classical

noncomputable def glue_uIcc (F : Icc a b → E) (G : uIcc b c → E) (t : Icc a c) : E :=
  if h : t ≤ b then F ⟨t, t.2.1, h⟩ else
    G ⟨t, inf_le_left.trans <| not_le.1 h |>.le, t.2.2.trans le_sup_right⟩

lemma glue_uIcc_eq (hab : a ≤ b) : glue_uIcc F G = λ t : Icc a c =>
    if t ≤ b then IccExtend hab F t else IccExtend inf_le_sup G t := by
  ext t ; simp [glue_uIcc] ; split_ifs <;> symm <;> apply IccExtend_of_mem

end uIcc
