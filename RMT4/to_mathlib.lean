import Mathlib.Analysis.Calculus.ParametricIntegral
import RMT4.cindex

local macro_rules | `($x ^ $y) => `(HPow.hPow $x $y)

open intervalIntegral Real MeasureTheory Filter Topology Set Metric

lemma isCompact_segment [OrderedRing 𝕜] [TopologicalSpace 𝕜] [TopologicalAddGroup 𝕜] [CompactIccSpace 𝕜]
    [TopologicalSpace E] [AddCommGroup E] [ContinuousAdd E] [Module 𝕜 E] [ContinuousSMul 𝕜 E] {x y : E} :
    IsCompact (segment 𝕜 x y) := by
  simpa only [segment_eq_image] using isCompact_Icc.image (by continuity)

lemma mem_closed_ball_neg_iff_mem_neg_closed_ball [SeminormedAddCommGroup V] {u v : V} :
    u ∈ closedBall (-v) r ↔ -u ∈ closedBall v r := by
  rw [← neg_closedBall r v]; rfl

lemma DifferentiableAt.deriv_eq_deriv_pow_div_pow {n : ℕ} (n_pos : 0 < n) {f g : ℂ → ℂ}
    (hg : ∀ᶠ z in 𝓝 z, f z = (g z) ^ n) (g_diff : DifferentiableAt ℂ g z) (fz_nonzero : f z ≠ 0) :
    deriv g z = deriv f z / (n * (g z) ^ (n - 1)) := by
  have h1 : g z ≠ 0 := λ h => fz_nonzero (by simp [Eventually.self_of_nhds hg, h, n_pos])
  have h2 : n * (g z) ^ (n - 1) ≠ 0 := by simp [pow_ne_zero, h1, n_pos.ne.symm]
  rw [(EventuallyEq.deriv hg).self_of_nhds, deriv_pow'' _ g_diff, eq_div_iff h2]
  ring

lemma Set.injOn_of_injOn_comp (hfg : InjOn (f ∘ g) s) : InjOn g s :=
  λ _ hx _ hy => hfg hx hy ∘ congr_arg f

lemma has_deriv_at_integral_of_continuous_of_lip
    {φ : ℂ → ℝ → ℂ} {ψ : ℝ → ℂ} {z₀ : ℂ} {a b C δ : ℝ} (hab : a ≤ b) (δ_pos : 0 < δ)
    (φ_cts : ∀ᶠ z in 𝓝 z₀, ContinuousOn (φ z) (Icc a b))
    (φ_der : ∀ t ∈ Ioc a b, HasDerivAt (λ x => φ x t) (ψ t) z₀)
    (φ_lip : ∀ t ∈ Ioc a b, LipschitzOnWith (Real.nnabs C) (λ x => φ x t) (ball z₀ δ))
    (ψ_cts : ContinuousOn ψ (Ioc a b)) :
    HasDerivAt (λ z => ∫ t in a..b, φ z t) (∫ t in a..b, ψ t) z₀ := by
  let μ : Measure ℝ := volume.restrict (Ioc a b)
  have h1 : ∀ᶠ z in 𝓝 z₀, AEStronglyMeasurable (φ z) μ :=
    φ_cts.mono (λ z h => (h.mono Ioc_subset_Icc_self).aestronglyMeasurable measurableSet_Ioc)
  have h2 : Integrable (φ z₀) μ :=
    φ_cts.self_of_nhds.integrableOn_Icc.mono_set Ioc_subset_Icc_self
  have h3 : AEStronglyMeasurable ψ μ := ψ_cts.aestronglyMeasurable measurableSet_Ioc
  have h4 : ∀ᵐ t ∂μ, LipschitzOnWith (Real.nnabs C) (λ z => φ z t) (ball z₀ δ) :=
    (ae_restrict_iff' measurableSet_Ioc).mpr (eventually_of_forall φ_lip)
  have h5 : Integrable (λ _ => C) μ := integrable_const _
  have h6 : ∀ᵐ t ∂μ, HasDerivAt (λ z => φ z t) (ψ t) z₀ :=
    (ae_restrict_iff' measurableSet_Ioc).mpr (eventually_of_forall φ_der)

  simpa [intervalIntegral, hab] using
    (hasDerivAt_integral_of_dominated_loc_of_lip δ_pos h1 h2 h3 h4 h5 h6).2

section uIoo

def uIoo (a b : ℝ) : Set ℝ := Ioo (a ⊓ b) (a ⊔ b)

lemma uIoo_eq_union : uIoo a b = (Ioo a b) ∪ (Ioo b a) := by
  cases le_total a b <;> simp [*, uIoo]

lemma mem_uIoo : t ∈ uIoo a b ↔ (a < t ∧ t < b) ∨ (b < t ∧ t < a) := by simp [uIoo_eq_union]

lemma uIoo_eq_uIoc_sdiff_ends : uIoo a b = Ι a b \ {a, b} := by
  ext t
  constructor <;> intro hh
  · simp [mem_uIoo] at hh
    cases hh with
    | inl h => simp [uIoc, h, h.2.le, h.1.ne.symm, h.2.ne]
    | inr h => simp [uIoc, h, h.2.le, h.1.ne.symm, h.2.ne]
  · simp_rw [uIoc, mem_diff, mem_Ioc, mem_insert_iff, mem_singleton_iff] at hh
    push_neg at hh
    refine ⟨hh.1.1, lt_of_le_of_ne hh.1.2 ?_⟩
    cases le_total a b <;> simp [*]

lemma uIoo_eq_uIcc_sdiff_ends : uIoo a b = uIcc a b \ {a, b} := by
  cases le_total a b
  · simp [uIoo, uIcc, *]
  · simp [uIoo, uIcc, *, pair_comm a b]

lemma uIoo_subset_uIcc : uIoo a b ⊆ uIcc a b := by
  cases le_total a b <;> simp [uIoo, uIcc, Ioo_subset_Icc_self, *]

lemma uIcc_mem_nhds (h : t ∈ uIoo a b) : uIcc a b ∈ 𝓝 t :=
  mem_of_superset (isOpen_Ioo.mem_nhds h) uIoo_subset_uIcc

lemma uIcc_mem_nhds_within (h : t ∈ uIoo a b) : uIcc a b ∈ 𝓝[Ioi t] t :=
  nhdsWithin_le_nhds (uIcc_mem_nhds h)

end uIoo

section helper_integral

variable [NormedAddCommGroup E] [NormedSpace ℝ E]

lemma lemma2' {γ : ℝ → E} : EqOn (derivWithin γ (uIcc t₁ t₂)) (deriv γ) (uIoo t₁ t₂) :=
  λ t ht => by simp [derivWithin, deriv, fderivWithin_of_mem_nhds (uIcc_mem_nhds ht)]

lemma lemma3' {f g : ℝ → E} (h : EqOn f g (uIoo t₁ t₂)) : ∫ t in t₁..t₂, f t = ∫ t in t₁..t₂, g t := by
  apply intervalIntegral.integral_congr_ae
  apply eventually_of_mem (U := {t₁, t₂}ᶜ)
  · simp only [mem_singleton_iff, mem_ae_iff, compl_compl]
    exact measure_union_null volume_singleton volume_singleton
  · rw [uIoo_eq_uIoc_sdiff_ends] at h
    exact λ t h1 h2 => h ⟨h2, h1⟩

end helper_integral

namespace ContDiffOn

variable [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]

open intervalIntegral

theorem integral_eq_sub_of_contDiffOn' {f : ℝ → E} (hab : a < b) (h : ContDiffOn ℝ 1 f (Icc a b)) :
    ∫ y in a..b, derivWithin f (Icc a b) y = f b - f a := by
  apply integral_eq_sub_of_hasDerivAt_of_le hab.le h.continuousOn
  · intro t ht
    apply ((h.differentiableOn le_rfl) t (Ioo_subset_Icc_self ht)).hasDerivWithinAt.hasDerivAt
    exact Icc_mem_nhds ht.1 ht.2
  · apply ContinuousOn.intervalIntegrable_of_Icc hab.le
    exact h.continuousOn_derivWithin (uniqueDiffOn_Icc hab) le_rfl

theorem integral_eq_sub_of_contDiffOn {f : ℝ → E} (hab : a ≤ b) (h : ContDiffOn ℝ 1 f (Icc a b)) :
    ∫ y in a..b, derivWithin f (Icc a b) y = f b - f a := by
  cases lt_or_eq_of_le hab
  · case inl hab => exact integral_eq_sub_of_contDiffOn' hab h
  · case inr hab => simp [hab]

theorem continuousOn_derivWithin'' {f : ℝ → E} (h : ContDiffOn ℝ n f (uIcc a b)) (hn : 1 ≤ n) :
    ContinuousOn (derivWithin f (uIcc a b)) (uIcc a b) := by
  by_cases hab : a = b
  · simp [continuousOn_singleton, hab]
  · refine h.continuousOn_derivWithin (uniqueDiffOn_Icc (min_lt_max.2 hab)) hn

theorem integral_derivWithin_smul_comp {f : ℝ → ℝ} {g : ℝ → E}
    (h : ContDiffOn ℝ 1 f (uIcc a b)) (hg : ContinuousOn g (f '' uIcc a b)) :
    (∫ x in a..b, derivWithin f (uIcc a b) x • (g ∘ f) x) = (∫ x in f a..f b, g x) := by
  refine integral_comp_smul_deriv'' h.continuousOn (λ t ht => ?_) (h.continuousOn_derivWithin'' le_rfl) hg
  apply (h.differentiableOn le_rfl t (uIoo_subset_uIcc ht)).hasDerivWithinAt.mono_of_mem
  exact uIcc_mem_nhds_within ht

theorem integral_eq_sub_of_contDiffOn''' {f : ℝ → E} (hab : a ≤ b) (h : ContDiffOn ℝ 1 f (Icc a b)) :
    ∫ y in a..b, deriv f y = f b - f a := by
  convert integral_eq_sub_of_contDiffOn hab h using 1
  apply lemma3'
  intro t ht
  convert (lemma2' ht).symm using 3
  simp [uIcc, hab]

theorem integral_eq_sub_of_contDiffOn_u {f : ℝ → E} (h : ContDiffOn ℝ 1 f (uIcc a b)) :
    ∫ y in a..b, deriv f y = f b - f a := by
  cases le_total a b <;> simp only [uIcc_of_le, uIcc_of_ge, *] at h
  · simp [integral_eq_sub_of_contDiffOn''', *]
  · simp [integral_symm b a, integral_eq_sub_of_contDiffOn''', *]

theorem integral_eq_sub_of_contDiffOn'' {f : ℝ → E} (hab : a ≤ b) (ht : t ∈ Icc a b)
  (h : ContDiffOn ℝ 1 f (Icc a b)) :
    ∫ y in a..t, derivWithin f (Icc a b) y = f t - f a := by
  have l1 : Icc a t ⊆ Icc a b := Icc_subset_Icc_right ht.2
  have l2 := integral_eq_sub_of_contDiffOn''' ht.1 (h.mono l1)
  rw [← l2]
  apply lemma3'
  intro u hu
  simp
  have l3 : u ∈ uIoo a b := by
    rw [uIoo_eq_uIoc_sdiff_ends]
    simp [uIoo_eq_uIoc_sdiff_ends, mem_uIoc] at hu
    cases hu.1
    · case inl hh =>
      simp [mem_uIoc]
      push_neg at hu ⊢
      refine ⟨Or.inl ⟨hh.1, hh.2.trans ht.2⟩, hu.2.1, ?_⟩
      intro hub
      subst_vars
      cases hu.2.2 (le_antisymm hh.2 ht.2)
    · case inr hh => linarith [ht.1]
  convert (lemma2' l3) using 2
  simp [uIcc, hab]

end ContDiffOn
