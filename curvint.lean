import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Order.Interval
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.Topology.PathConnected
import RMT4.to_mathlib

open intervalIntegral Real MeasureTheory Filter Topology Set Metric

section definitions

variable [TopologicalSpace 𝕜] [NormedAddCommGroup 𝕜] [NormedSpace ℝ 𝕜] [HSMul 𝕜 E E] [NormedAddCommGroup E]
  [NormedSpace ℝ E]

/-- We start with a basic definition of the integral of a function along a path, which makes sense
  when the path is differentiable -/

noncomputable def pintegral (t₁ t₂ : ℝ) (f : 𝕜 → E) (γ : ℝ → 𝕜) : E :=
  ∫ t in t₁..t₂, deriv γ t • f (γ t)

structure contour (𝕜 : Type) := (a : ℝ) (b : ℝ) (toFun : ℝ → 𝕜)

instance : CoeFun (contour 𝕜) (λ _ => ℝ → 𝕜) := ⟨contour.toFun⟩

noncomputable def cintegral (γ : contour 𝕜) (f : 𝕜 → E) : E :=
  ∫ t in γ.a..γ.b, deriv γ t • f (γ t)

example {f : 𝕜 → E} {γ : contour 𝕜} : pintegral γ.a γ.b f γ = cintegral γ f := rfl

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

lemma pintegral'_eq_pintegral {f : 𝕜 → E} {γ : ℝ → 𝕜} : pintegral' a b f γ = pintegral a b f γ :=
  integral_congr_uIoo (λ _ ht => congr_arg₂ _ (derivWithin_of_mem_uIoo ht) rfl)

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
  simp_rw [← pintegral'_eq_pintegral]
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

theorem cdv [ContinuousSMul 𝕜 E]
    (φ_diff : ContDiffOn ℝ 1 φ (uIcc a b))
    (φ_maps : φ '' uIcc a b = uIcc (φ a) (φ b))
    (γ_diff : ContDiffOn ℝ 1 γ (uIcc (φ a) (φ b)))
    (f_cont : ContinuousOn f (γ '' uIcc (φ a) (φ b)))
    :
    pintegral (φ a) (φ b) f γ = pintegral a b f (γ ∘ φ) := by
  have l1 : ContinuousOn (fun x => derivWithin γ (uIcc (φ a) (φ b)) x • f (γ x)) (φ '' uIcc a b) := by
    have e1 := γ_diff.continuousOn_derivWithin'' le_rfl
    have e2 := f_cont.comp γ_diff.continuousOn (mapsTo_image _ _)
    simpa only [φ_maps] using e1.smul e2
  simp_rw [← pintegral'_eq_pintegral, pintegral', ← φ_diff.integral_derivWithin_smul_comp l1]
  refine integral_congr_uIoo (λ t ht => ?_)
  have l2 : MapsTo φ (uIcc a b) (uIcc (φ a) (φ b)) := φ_maps ▸ mapsTo_image _ _
  have l6 : t ∈ uIcc a b := uIoo_subset_uIcc ht
  have l3 : DifferentiableWithinAt ℝ γ (uIcc (φ a) (φ b)) (φ t) := γ_diff.differentiableOn le_rfl (φ t) (l2 l6)
  have l4 : DifferentiableWithinAt ℝ φ (uIcc a b) t := (φ_diff t l6).differentiableWithinAt le_rfl
  have l5 : UniqueDiffWithinAt ℝ (uIcc a b) t := uniqueDiffWithinAt_of_mem_nhds (uIcc_mem_nhds ht)
  simp [derivWithin.scomp t l3 l4 l2 l5]

end bla

section holo

variable (Γ Γ' : ℝ → ℝ → ℂ) (f f' : ℂ → ℂ) (a b u₀ : ℝ)

theorem holo
    (hab : a ≤ b)
    (hcycle : ∀ u, Γ u b = Γ u a)
    (hcycle' : ∀ u, Γ' u b = Γ' u a)
    :
    HasDerivAt (λ u => pintegral a b f (Γ u)) 0 u₀
    := by

  simp [pintegral, intervalIntegral, hab]

  set μ : Measure ℝ := volume.restrict (Ioc a b)
  set F : ℝ → ℝ → ℂ := λ u t => deriv (Γ u) t * f (Γ u t)
  set F' : ℝ → ℝ → ℂ := λ u t => deriv (Γ' u) t * f (Γ u t) + deriv (Γ u) t * Γ' u t * f' (Γ u t) with def_F'
  set G : ℝ → ℂ := λ s => Γ' u₀ s * f (Γ u₀ s) with def_G
  set C : ℝ → ℝ := sorry
  set ε : ℝ := sorry
  have hε : 0 < ε := sorry

  have h1 : ∀ᶠ x in 𝓝 u₀, AEStronglyMeasurable (F x) μ := sorry

  have h2 : Integrable (F u₀) μ := sorry

  have h3 : AEStronglyMeasurable (F' u₀) μ := sorry

  have h4 : ∀ᵐ t ∂μ, ∀ u ∈ ball u₀ ε, ‖F' u t‖ ≤ C t := sorry

  have h5 : Integrable C μ := sorry

  have h6 : ∀ᵐ t ∂μ, ∀ u ∈ ball u₀ ε, HasDerivAt (F · t) (F' u t) u := by sorry

  convert ← (hasDerivAt_integral_of_dominated_loc_of_deriv_le hε h1 h2 h3 h4 h5 h6).2

  have h7 : ∀ u t, F' u t = deriv G t := sorry

  simp [h7]

  have h8 : ∀ x ∈ uIcc a b, DifferentiableAt ℝ G x := sorry

  have h9 : IntervalIntegrable (deriv G) volume a b := sorry

  have := @integral_deriv_eq_sub ℂ _ _ _ G a b h8 h9

  simpa [def_G, intervalIntegral, hab, hcycle, hcycle'] using this

end holo