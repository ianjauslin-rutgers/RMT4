import Mathlib.Tactic
import Mathlib.Analysis.Calculus.ContDiffDef
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral
import Mathlib.Topology.LocallyConstant.Basic
import Mathlib.Analysis.Calculus.MeanValue
import RMT4.Subdivision

open BigOperators Metric Set Subdivision Topology Filter Nat

structure LocalPrimitiveOn (s : Set ℂ) (f : ℂ → ℂ) :=
  F : s → ℂ → ℂ
  S : s → Set ℂ
  mem z : z.1 ∈ S z
  opn z : IsOpen (S z)
  dif z : DifferentiableOn ℂ (F z) (S z)
  eqd z : (S z).EqOn (deriv (F z)) f

namespace LocalPrimitiveOn

lemma nhd (h : LocalPrimitiveOn s f) (z : s) : h.S z ∈ 𝓝 z.1 :=
  (h.opn z).mem_nhds (h.mem z)

def restrict (Λ : LocalPrimitiveOn s f) (h : t ⊆ s) : LocalPrimitiveOn t f where
  F := Λ.F ∘ inclusion h
  S := Λ.S ∘ inclusion h
  mem z := Λ.mem (inclusion h z)
  opn z := Λ.opn (inclusion h z)
  dif z := Λ.dif (inclusion h z)
  eqd z := Λ.eqd (inclusion h z)

def zero : LocalPrimitiveOn univ 0 where
  F _ := 0
  S _ := univ
  mem _ := mem_univ _
  opn _ := isOpen_univ
  dif _ := differentiableOn_const _
  eqd _ := by
    change EqOn (deriv (λ _ => 0)) 0 univ
    simpa only [deriv_const'] using eqOn_refl _ _

noncomputable def deriv {{U : Set ℂ}}  (hU : IsOpen U) {{F : ℂ → ℂ}} (hF : DifferentiableOn ℂ F U) :
    LocalPrimitiveOn U (deriv F) where
  F _ := F
  S _ := U
  mem z := z.2
  opn _ := hU
  eqd _ := eqOn_refl _ _
  dif _ := hF

end LocalPrimitiveOn

def HasLocalPrimitiveOn (U : Set ℂ) (f : ℂ → ℂ) : Prop := Nonempty (LocalPrimitiveOn U f)

namespace HasLocalPrimitiveOn

lemma mono (h : HasLocalPrimitiveOn U f) (hVU : V ⊆ U) : HasLocalPrimitiveOn V f :=
  ⟨h.some.restrict hVU⟩

lemma zero : HasLocalPrimitiveOn s 0 := ⟨LocalPrimitiveOn.zero.restrict (subset_univ _)⟩

lemma deriv (hU : IsOpen U) (hF : DifferentiableOn ℂ F U) : HasLocalPrimitiveOn U (deriv F) :=
  ⟨LocalPrimitiveOn.deriv hU hF⟩

end HasLocalPrimitiveOn

section pintegral

variable {a b : ℝ} {γ : ℝ → ℂ} {f : ℂ → ℂ}

noncomputable def pintegral_aux (hab : a < b) (hγ : ContinuousOn γ (Icc a b))
    (Λ : LocalPrimitiveOn (γ '' Icc a b) f) : ℂ :=
  have h1 (t : Icc a b) : ∃ i : γ '' Icc a b, Λ.S i ∈ 𝓝 (γ t) := ⟨⟨γ t, t, t.2, rfl⟩, Λ.nhd _⟩
  let RW := exists_reladapted hab hγ h1
  RW.σ.sumSubAlong (Λ.F ∘ RW.I) γ

noncomputable def pintegral (a b : ℝ) (f : ℂ → ℂ) (γ : ℝ → ℂ) : ℂ := by
  by_cases h : a < b ∧ ContinuousOn γ (Icc a b) ∧ HasLocalPrimitiveOn (γ '' Icc a b) f
  · exact pintegral_aux h.1 h.2.1 h.2.2.some
  · exact 0

lemma isLocallyConstant_of_deriv_eq_zero (hU : IsOpen U) {f : ℂ → ℂ} (h : DifferentiableOn ℂ f U)
    (hf : U.EqOn (deriv f) 0) :
    IsLocallyConstant (U.restrict f) := by
  refine (IsLocallyConstant.iff_exists_open _).2 (λ ⟨z, hz⟩ => ?_)
  obtain ⟨ε, L1, L2⟩ := isOpen_iff.1 hU z hz
  refine ⟨ball ⟨z, hz⟩ ε, isOpen_ball, mem_ball_self L1, λ ⟨z', _⟩ hz' => ?_⟩
  refine (convex_ball z ε).is_const_of_fderivWithin_eq_zero (h.mono L2) ?_ hz' (mem_ball_self L1)
  intro x hx
  rw [fderivWithin_eq_fderiv (isOpen_ball.uniqueDiffWithinAt hx)]
  · exact ContinuousLinearMap.ext_ring (hf (L2 hx))
  · exact h.differentiableAt (hU.mem_nhds (L2 hx))

lemma apply_eq_of_path (hab : a ≤ b) {f : ℂ → ℂ} (hf : IsLocallyConstant (U.restrict f))
    {γ : ℝ → ℂ} (hγ : ContinuousOn γ (Icc a b)) (h : MapsTo γ (Icc a b) U) :
    f (γ b) = f (γ a) := by
  haveI : PreconnectedSpace (Icc a b) := isPreconnected_iff_preconnectedSpace.1 isPreconnected_Icc
  have h2 := hf.comp_continuous (hγ.restrict_mapsTo h)
  exact @IsLocallyConstant.apply_eq_of_isPreconnected _ _ _ _ (h2) _ isPreconnected_univ
    ⟨b, hab, le_rfl⟩ ⟨a, le_rfl, hab⟩ (mem_univ _) (mem_univ _)

lemma sumSubAlong_eq_zero (hab : a < b) {DW : LocalPrimitiveOn U 0}
  {RW : reladapted a b DW.S γ} (hγ : ContinuousOn γ (Icc a b)) :
    RW.σ.sumSubAlong (DW.F ∘ RW.I) γ = 0 := by
  refine Subdivision.sum_eq_zero (λ k => (sub_eq_zero.2 ?_))
  apply apply_eq_of_path (RW.σ.mono' hab).le
  · apply isLocallyConstant_of_deriv_eq_zero (DW.opn _) (DW.dif _)
    exact λ _ hz => DW.eqd (RW.I k) hz
  · exact hγ.mono (RW.σ.piece_subset hab.le)
  · exact mapsTo'.2 (RW.sub k)

@[simp] lemma pintegral_zero (hab : a < b) (hγ : ContinuousOn γ (Icc a b)) :
    pintegral a b 0 γ = 0 := by
  have : HasLocalPrimitiveOn (γ '' Icc a b) 0 := ⟨LocalPrimitiveOn.zero.restrict (subset_univ _)⟩
  simp [pintegral, hab, hγ, this, pintegral_aux, sumSubAlong_eq_zero]

end pintegral

lemma sub_eq_sub_of_deriv_eq_deriv (hab : a ≤ b) (hU : IsOpen U)
    {γ : ℝ → ℂ} (hγ₁ : ContinuousOn γ (Icc a b)) (hγ₂ : MapsTo γ (Icc a b) U)
    {f g : ℂ → ℂ} (hf : DifferentiableOn ℂ f U) (hg : DifferentiableOn ℂ g U)
    (hfg : ∀ z ∈ U, deriv f z = deriv g z) :
    f (γ b) - f (γ a) = g (γ b) - g (γ a) := by
  rw [sub_eq_sub_iff_sub_eq_sub]
  change (f - g) (γ b) = (f - g) (γ a)
  refine apply_eq_of_path (U := U) hab ?_ hγ₁ hγ₂
  refine isLocallyConstant_of_deriv_eq_zero hU (hf.sub hg) (λ z hz => ?_)
  have h1 : DifferentiableAt ℂ f z := hf.differentiableAt (hU.mem_nhds hz)
  have h2 : DifferentiableAt ℂ g z := hg.differentiableAt (hU.mem_nhds hz)
  have h3 : deriv (f - g) z = deriv f z - deriv g z := deriv_sub h1 h2
  simp [hfg z hz, h3]

lemma sumSubAlong_eq_of_sigma (hab : a < b) {hf : LocalPrimitiveOn U f} {RW₁ RW₂ : reladapted a b hf.S γ}
    (h : RW₁.σ = RW₂.σ) (hγ : ContinuousOn γ (Icc a b)) :
    RW₁.σ.sumSubAlong (hf.F ∘ RW₁.I) γ = RW₂.σ.sumSubAlong (hf.F ∘ RW₂.I) γ := by
  rcases hf with ⟨F, S, _, Sopn, Sdif, Seqd⟩
  rcases RW₁ with ⟨σ, I₁, hI₁⟩
  rcases RW₂ with ⟨σ', I₂, hI₂⟩
  subst h
  refine Subdivision.sum_congr (λ k => ?_)
  apply sub_eq_sub_of_deriv_eq_deriv (σ.mono' hab).le ((Sopn _).inter (Sopn _))
  · exact (hγ.mono (σ.piece_subset hab.le))
  · simpa only [mapsTo'] using subset_inter (hI₁ k) (hI₂ k)
  · exact (Sdif _).mono (inter_subset_left _ _)
  · exact (Sdif _).mono (inter_subset_right _ _)
  · exact λ z hz => (Seqd _ hz.1).trans (Seqd _ hz.2).symm

lemma telescopic (f : Fin (n + 1) → ℂ) :
    ∑ i : Fin n, (f i.succ - f i.castSucc) = f (Fin.last n) - f 0 := by
  have l1 : ∑ i : Fin n, f (i.succ) = ∑ i : Fin (n + 1), f i - f 0 := by
    simp [Fin.sum_univ_succ f]
  have l2 : ∑ i : Fin n, f (i.castSucc) = ∑ i : Fin (n + 1), f i - f (Fin.last n) := by
    simp [Fin.sum_univ_castSucc f]
  simp [l1, l2]

lemma sumSubAlong_eq_sub
    (hab : a < b)
    (hF : DifferentiableOn ℂ F U)
    (hf : LocalPrimitiveOn (γ '' Icc a b) (deriv F))
    (hγ : ContinuousOn γ (Icc a b))
    (RW : reladapted a b hf.S γ)
    (hU : IsOpen U)
    (hh : MapsTo γ (Icc a b) U) :
    RW.σ.sumSubAlong (hf.F ∘ RW.I) γ = F (γ b) - F (γ a) := by
  have key (i) : ((hf.F ∘ RW.I) i ∘ γ) (RW.σ.y i) - ((hf.F ∘ RW.I) i ∘ γ) (RW.σ.x i) =
      F (γ (RW.σ.y i)) - F (γ (RW.σ.x i)) := by
    apply sub_eq_sub_of_deriv_eq_deriv (U := hf.S (RW.I i) ∩ U)
    · exact (RW.σ.mono' hab).le
    · exact (hf.opn (RW.I i)).inter hU
    · exact hγ.mono (RW.σ.piece_subset hab.le)
    · exact (Set.mapsTo'.2 (RW.sub i)).inter (hh.mono_left (RW.σ.piece_subset hab.le))
    · exact (hf.dif (RW.I i)).mono (inter_subset_left _ _)
    · exact DifferentiableOn.mono hF (inter_subset_right _ _)
    · exact λ z hz => hf.eqd (RW.I i) hz.1
  simp only [sumSubAlong, sumSub, sum, key]
  convert telescopic (F ∘ γ ∘ RW.σ)
  simp only [← RW.σ.last] ; rfl

lemma pintegral_deriv {F : ℂ → ℂ} {γ : ℝ → ℂ} (hab : a < b) (hU : IsOpen U)
    (hγ : ContinuousOn γ (Icc a b)) (h2 : MapsTo γ (Icc a b) U) (hF : DifferentiableOn ℂ F U) :
    pintegral a b (deriv F) γ = F (γ b) - F (γ a) := by
  simpa [pintegral, hab, hγ, (HasLocalPrimitiveOn.deriv hU hF).mono (mapsTo'.1 h2)]
  using sumSubAlong_eq_sub hab hF _ hγ _ hU h2