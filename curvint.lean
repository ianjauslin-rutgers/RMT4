import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Order.Interval
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.Topology.PathConnected

open intervalIntegral Real MeasureTheory Filter Topology Set Metric

section definitions

variable [TopologicalSpace 𝕜] [NormedAddCommGroup 𝕜] [NormedSpace ℝ 𝕜] [HSMul 𝕜 E E] [NormedAddCommGroup E]
  [NormedSpace ℝ E]

/-- We start with a basic definition of the integral of a function along a path, which makes sense
  when the path is differentiable -/

noncomputable def pintegral (t₁ t₂ : ℝ) (f : 𝕜 → E) (γ : ℝ → 𝕜) : E :=
  ∫ t in t₁..t₂, deriv γ t • f (γ t)

-- the definition is defeq to `circleIntegral` when appropriate:
lemma circleIntegral_eq_pintegral2 {f : ℂ → ℂ} :
    (∮ z in C(c, R), f z) = (pintegral 0 (2 * π) f (circleMap c R)) := rfl

-- a version using `Path` (but it loses all the Path API):
noncomputable def pintegral2 (f : 𝕜 → E) {x y : 𝕜} (γ : Path x y) : E :=
    pintegral 0 1 f γ.extend

-- integral against a `Path`, has the Path API but is tedious to use

noncomputable def pderiv {x y : 𝕜} (γ : Path x y) (t : unitInterval) : 𝕜 := deriv γ.extend t

noncomputable def pintegral1' (f : 𝕜 → E) {x y : 𝕜} (γ : Path x y) : E :=
  ∫ t, pderiv γ t • f (γ t)

/-- Some plumbing -/

noncomputable def circlePath (c : ℂ) (R : ℝ) : Path (c + R) (c + R) where
  toFun := λ t => circleMap c R (2 * π * t)
  source' := by simp [circleMap]
  target' := by simp [circleMap]

noncomputable def toPath (t₁ t₂ : ℝ) (γ : ℝ → 𝕜) (h1 : ContinuousOn γ (Set.Icc t₁ t₂)) (h2 : t₁ < t₂) :
    Path (γ t₁) (γ t₂) where
  toFun := λ t => γ ((iccHomeoI t₁ t₂ h2).symm t)
  continuous_toFun := by
    apply h1.comp_continuous
    · exact continuous_subtype_val.comp (iccHomeoI t₁ t₂ h2).symm.continuous_toFun
    · exact λ t => Subtype.mem _
  source' := by simp
  target' := by simp

example {c : ℂ} {R : ℝ} : (circlePath c R).cast (by simp [circleMap]) (by simp [circleMap]) =
    toPath 0 (2 * π) (circleMap c R) (continuous_circleMap c R).continuousOn two_pi_pos := by
  ext1; simp [toPath, circlePath]

/-- Version with `deriv_within` is useful -/

noncomputable def pintegral' (t₁ t₂ : ℝ) (f : 𝕜 → E) (γ : ℝ → 𝕜) : E :=
  ∫ t in t₁..t₂, derivWithin γ (Set.uIcc t₁ t₂) t • f (γ t)

lemma uIcc_mem_nhds {t t₁ t₂ : ℝ} (h1 : t ∈ Ι t₁ t₂) (h2 : t ≠ t₁) (h3 : t ≠ t₂) :
    Set.uIcc t₁ t₂ ∈ 𝓝 t := by
  rw [Set.mem_uIoc] at h1
  apply Icc_mem_nhds
  · match h1 with
    | Or.inl h => exact inf_le_left.trans_lt h.1
    | Or.inr h => exact inf_le_right.trans_lt h.1
  · match h1 with
    | Or.inl h => exact lt_of_le_of_lt' le_sup_right (lt_of_le_of_ne h.2 h3)
    | Or.inr h => exact lt_of_le_of_lt' le_sup_left (lt_of_le_of_ne h.2 h2)

lemma uIcc_mem_nhds' {t t₁ t₂ : ℝ} (h1 : t ∈ Ι t₁ t₂ \ {t₁, t₂}) :
    Set.uIcc t₁ t₂ ∈ 𝓝 t := by
  simp [mem_uIoc] at h1
  push_neg at h1
  apply Icc_mem_nhds
  · match h1.1 with
    | Or.inl h => exact inf_le_left.trans_lt h.1
    | Or.inr h => exact inf_le_right.trans_lt h.1
  · match h1.1 with
    | Or.inl h => exact lt_of_le_of_lt' le_sup_right (lt_of_le_of_ne h.2 h1.2.2)
    | Or.inr h => exact lt_of_le_of_lt' le_sup_left (lt_of_le_of_ne h.2 h1.2.1)

lemma lemma2 {γ : ℝ → 𝕜} {x : ℝ} (h : x ∈ Ι t₁ t₂ \ {t₁, t₂}) :
    derivWithin γ (uIcc t₁ t₂) x = deriv γ x := by
  simp [derivWithin, deriv, fderivWithin_of_mem_nhds (uIcc_mem_nhds' h)]

lemma lemma4 {γ : ℝ → 𝕜} : EqOn (derivWithin γ (uIcc t₁ t₂)) (deriv γ) (Ι t₁ t₂ \ {t₁, t₂}) := by
  intro t ht
  simp [derivWithin, deriv, fderivWithin_of_mem_nhds (uIcc_mem_nhds' ht)]

lemma lemma3 {f g : ℝ → E} (h : EqOn f g (uIoc t₁ t₂ \ {t₁, t₂})) :
    ∫ t in t₁..t₂, f t = ∫ t in t₁..t₂, g t := by
  apply intervalIntegral.integral_congr_ae
  apply eventually_of_mem (U := {t₁, t₂}ᶜ)
  · simp only [mem_singleton_iff, mem_ae_iff, compl_compl]
    exact measure_union_null volume_singleton volume_singleton
  · aesop

lemma pintegral'_eq_pintegral : (pintegral' : ℝ → ℝ → (𝕜 → E) → (ℝ → 𝕜) → E) = pintegral := by
  ext t₁ t₂ f γ
  apply lemma3
  intro t ht
  simp [lemma4 ht]

end definitions

/- Differentiate wrt the function along a fixed contour -/

section derivcurvint

variable
  [IsROrC 𝕜] [NormedSpace ℝ 𝕜]
  [NormedAddCommGroup E] [CompleteSpace E] [NormedSpace ℝ E] [NormedSpace 𝕜 E]
  {t₁ t₂ : ℝ} {F F' : 𝕜 → 𝕜 → E}

theorem hasDerivAt_curvint (ht : t₁ < t₂)
    (γ_diff : ContDiffOn ℝ 1 γ (Icc t₁ t₂))
    (F_cont : ∀ᶠ i in 𝓝 i₀, ContinuousOn (F i) (γ '' Icc t₁ t₂))
    (F_deri : ∀ᶠ i in 𝓝 i₀, ∀ t ∈ Icc t₁ t₂, HasDerivAt (λ i => F i (γ t)) (F' i (γ t)) i)
    (F'_cont : ContinuousOn (F' i₀) (γ '' Icc t₁ t₂))
    (F'_norm : ∀ᶠ i in 𝓝 i₀, ∀ t ∈ Icc t₁ t₂, ‖F' i (γ t)‖ ≤ C)
    :
    HasDerivAt (λ i => pintegral t₁ t₂ (F i) γ) (pintegral t₁ t₂ (F' i₀) γ) i₀ := by
  rw [← pintegral'_eq_pintegral]
  set μ : Measure ℝ := volume.restrict (Ioc t₁ t₂)
  set φ : 𝕜 → ℝ → E := λ i t => derivWithin γ (Icc t₁ t₂) t • F i (γ t)
  set ψ : 𝕜 → ℝ → E := λ i t => derivWithin γ (Icc t₁ t₂) t • F' i (γ t)
  obtain ⟨δ, hδ, h_in_δ⟩ := eventually_nhds_iff_ball.mp (F_deri.and F'_norm)

  have γ'_cont : ContinuousOn (derivWithin γ (Icc t₁ t₂)) (Icc t₁ t₂) :=
    γ_diff.continuousOn_derivWithin (uniqueDiffOn_Icc ht) le_rfl
  obtain ⟨C', h⟩ := (isCompact_Icc.image_of_continuousOn γ'_cont).bounded.subset_ball 0

  have φ_cont : ∀ᶠ i in 𝓝 i₀, ContinuousOn (φ i) (Icc t₁ t₂) := by
    filter_upwards [F_cont] with i h
    exact γ'_cont.smul (h.comp γ_diff.continuousOn (mapsTo_image _ _))

  have φ_meas : ∀ᶠ i in 𝓝 i₀, AEStronglyMeasurable (φ i) μ := by
    filter_upwards [φ_cont] with i h
    exact (h.mono Ioc_subset_Icc_self).aestronglyMeasurable measurableSet_Ioc

  have φ_intg : Integrable (φ i₀) μ :=
    φ_cont.self_of_nhds.integrableOn_Icc.mono_set Ioc_subset_Icc_self

  have φ_deri : ∀ᵐ t ∂μ, ∀ i ∈ ball i₀ δ, HasDerivAt (λ j => φ j t) (ψ i t) i := by
    refine (ae_restrict_iff' measurableSet_Ioc).mpr (eventually_of_forall ?_)
    intro t ht i hi
    apply ((h_in_δ i hi).1 t (Ioc_subset_Icc_self ht)).const_smul

  have ψ_cont : ContinuousOn (ψ i₀) (Icc t₁ t₂) :=
    γ'_cont.smul (F'_cont.comp γ_diff.continuousOn (mapsTo_image _ _))

  have ψ_meas : AEStronglyMeasurable (ψ i₀) μ :=
    (ψ_cont.mono Ioc_subset_Icc_self).aestronglyMeasurable measurableSet_Ioc

  have ψ_norm : ∀ᵐ t ∂μ, ∀ x ∈ ball i₀ δ, ‖ψ x t‖ ≤ C' * C := by
    refine (ae_restrict_iff' measurableSet_Ioc).mpr (eventually_of_forall (λ t ht w hw => ?_))
    rw [norm_smul]
    have e1 := mem_closedBall_zero_iff.mp (h (mem_image_of_mem _ (Ioc_subset_Icc_self ht)))
    have e2 := (h_in_δ w hw).2 t (Ioc_subset_Icc_self ht)
    exact mul_le_mul e1 e2 (norm_nonneg _) ((norm_nonneg _).trans e1)

  have hC : Integrable (λ (_ : ℝ) => C' * C) μ := integrable_const _

  simpa [pintegral', intervalIntegral, ht.le]
    using (hasDerivAt_integral_of_dominated_loc_of_deriv_le hδ φ_meas φ_intg ψ_meas ψ_norm hC φ_deri).2

end derivcurvint

section bla

variable
  [NormedAddCommGroup 𝕜] [NormedSpace ℝ 𝕜]
  [NormedAddCommGroup E] [CompleteSpace E] [NormedSpace ℝ E] [SMul 𝕜 E] [IsScalarTower ℝ 𝕜 E]
  {γ : ℝ → 𝕜} {φ φ' : ℝ → ℝ} {f : 𝕜 → E}

theorem lemma5
    [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F]
    {f : ℝ → ℝ} {f' : ℝ → ℝ}
    (hf' : ∀ s, HasDerivWithinAt f (f' s) (uIcc s₁ s₂) s)
    (hf : Set.InjOn f (uIcc s₁ s₂))
    (hf2 : f '' uIcc s₁ s₂ = uIcc t₁ t₂)
    (g : ℝ → F)
    :
    ∫ t in t₁..t₂, g t = ∫ s in s₁..s₂, |f' s| • g (f s) := by
  sorry

theorem cdv
    (h4 : ∀ t, |deriv φ t| = deriv φ t)
    (h10 : ∀ t, DifferentiableWithinAt ℝ φ (uIcc s₁ s₂) t)
    (h11 : ∀ t, DifferentiableWithinAt ℝ γ (uIcc t₁ t₂) (φ t))
    (h12 : MapsTo φ (uIcc s₁ s₂) (uIcc t₁ t₂))
    (h13 : ∀ t, UniqueDiffWithinAt ℝ (uIcc s₁ s₂) t)
    (h14 : φ '' uIcc s₁ s₂ = uIcc t₁ t₂)
    (h15 : ∀ s, HasDerivWithinAt φ (deriv φ s) (uIcc s₁ s₂) s)
    (h16 : InjOn φ (uIcc s₁ s₂))
    :
    pintegral t₁ t₂ f γ = pintegral s₁ s₂ f (γ ∘ φ) := by

  have H1 : ∀ t, derivWithin (γ ∘ φ) (uIcc s₁ s₂) t =
      derivWithin φ (uIcc s₁ s₂) t • derivWithin γ (uIcc t₁ t₂) (φ t) :=
    λ t => derivWithin.scomp t (h11 t) (h10 t) h12 (h13 t)

  have H2 := lemma5 h15 h16 h14 (λ t => derivWithin γ (uIcc t₁ t₂) t • f (γ t))

  simpa only [← pintegral'_eq_pintegral, pintegral', H2, h4, H1, Function.comp_apply, smul_assoc]
    using lemma3 (λ t ht => by rw [lemma4 ht])

end bla

