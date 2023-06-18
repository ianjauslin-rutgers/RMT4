import RMT4.hurwitz

open Complex Metric circleIntegral Topology Filter

variable {U : Set ℂ}

-- open filter set metric complex circle_integral
-- open_locale topological_space

-- variables {f g : ℂ → ℂ} {z z₀ c : ℂ} {r : ℝ} {U : set ℂ} {p : formal_multilinear_series ℂ ℂ ℂ}

-- -- TODO: mix with local_index_theorem with the order of the zero

lemma crucial (hU : IsOpen U) (hcr : closedBall c r ⊆ U) (hz₀ : z₀ ∈ ball c r) (hf : DifferentiableOn ℂ f U)
    (hfz₀ : f z₀ = 0) (hf'z₀ : deriv f z₀ ≠ 0) (hfz : ∀ z ∈ closedBall c r, z ≠ z₀ → f z ≠ 0) :
    cindex c r f = 1 := by
  have hr : 0 < r := dist_nonneg.trans_lt hz₀
  set g := dslope f z₀
  have h1 : DifferentiableOn ℂ g U :=
    (differentiableOn_dslope (hU.mem_nhds (hcr (ball_subset_closedBall hz₀)))).2 hf
  have h2 : ∀ z ∈ closedBall c r, g z ≠ 0 := by
    rintro z hz
    by_cases z = z₀
    case pos => simp [dslope, h, Function.update, hf'z₀]
    case neg => simp [dslope, h, Function.update, slope, sub_ne_zero.2 h, hfz₀, hfz z hz h]
  have h10 : ∀ z ∈ sphere c r, z - z₀ ≠ 0 :=
    λ z hz => sub_ne_zero.2 (sphere_disjoint_ball.ne_of_mem hz hz₀)
  suffices : cindex c r f = ((2 * Real.pi * I)⁻¹ * ∮ z in C(c, r), (z - z₀)⁻¹) + cindex c r g
  { rw [this, integral_sub_inv_of_mem_ball hz₀, cindex_eq_zero hU hr hcr h1 h2]
    field_simp [two_ne_zero, Real.pi_ne_zero, I_ne_zero] }
  have h6 : ∀ z ∈ sphere c r, deriv f z / f z = (z - z₀)⁻¹ + deriv g z / g z := by
    rintro z hz
    have h3 : ∀ z ∈ U, f z = (z - z₀) * g z :=
      λ z _ => by simpa only [smul_eq_mul, hfz₀, sub_zero] using (sub_smul_dslope f z₀ z).symm
    have hz' : z ∈ U := hcr (sphere_subset_closedBall hz)
    have e0 : U ∈ 𝓝 z := hU.mem_nhds hz'
    have h4 : deriv f z = deriv (λ w => (w - z₀) * g w) z :=
      EventuallyEq.deriv_eq (eventually_of_mem e0 h3)
    have e1 : DifferentiableAt ℂ (λ y => y - z₀) z := differentiableAt_id.sub_const z₀
    have e2 : DifferentiableAt ℂ g z := h1.differentiableAt e0
    have h5 : deriv f z = g z + (z - z₀) * deriv g z := by
      have : deriv (fun y => y - z₀) z = 1 := by
        change deriv (fun y => id y - z₀) z = 1
        simp [deriv_sub_const]
      simp [h4, deriv_mul e1 e2, this]
    have e3 : g z ≠ 0 := h2 z (sphere_subset_closedBall hz)
    field_simp [h3 z hz', h5, mul_comm, h10 z hz]
  simp only [cindex, integral_congr hr.le h6, ← mul_add]
  congr
  refine circleIntegral.add hr.le ((continuousOn_id.sub (continuousOn_const)).inv₀ h10) ?_
  refine ContinuousOn.div ?_ ?_ ?_
  { exact (h1.deriv hU).continuousOn.mono (sphere_subset_closedBall.trans hcr) }
  { exact h1.continuousOn.mono (sphere_subset_closedBall.trans hcr) }
  { exact λ z hz => h2 z (sphere_subset_closedBall hz) }

lemma tendsto_uniformly_on_const {f : α → β} [UniformSpace β] {p : Filter ι} {s : Set α} :
  TendstoUniformlyOn (λ _ => f) f p s :=
UniformOnFun.tendsto_iff_tendstoUniformlyOn.1 tendsto_const_nhds s (Set.mem_singleton _)

-- lemma bla (hf : analytic_at ℂ f z₀)
--   (hf' : has_fpower_series_at (deriv f) (0 : formal_multilinear_series ℂ ℂ ℂ) z₀) :
--   ∀ᶠ z in 𝓝 z₀, f z = f z₀ :=
-- begin
--   have h1 : ∀ᶠ z in 𝓝 z₀, analytic_at ℂ f z := (IsOpen_analytic_at ℂ f).mem_nhds hf,
--   obtain ⟨ε, hε, h⟩ := metric.mem_nhds_iff.1 (h1.and hf'.eventually_eq_zero),
--   refine metric.mem_nhds_iff.2 ⟨ε, hε, λ z hz, _⟩,
--   have h3 : ∀ z ∈ Ball z₀ ε, fderiv_within ℂ f (ball z₀ ε) z = 0,
--   { rintro z hz,
--     rw fderiv_within_eq_fderiv (IsOpen_ball.unique_diff_within_at hz) ((h hz).1.DifferentiableAt),
--     ext1,
--     simpa [fderiv_deriv] using (h hz).2 },
--   have h4 : DifferentiableOn ℂ f (ball z₀ ε) := λ z hz, (h hz).1.differentiable_within_at,
--   exact convex.is_const_of_fderiv_within_eq_zero (convex_ball z₀ ε) h4 h3 hz (mem_ball_self hε)
-- end

-- lemma two_le_order_of_deriv_eq_zero (hgp : has_fpower_series_at g p z₀) (hp : p ≠ 0)
--   (hg : g z₀ = 0) (hg' : deriv g z₀ = 0) :
--   2 ≤ p.order :=
-- begin
--   classical,
--   have h1 : p.coeff 1 = 0 := by simpa only [hg'] using hgp.deriv.symm,
--   have h2 : p 0 = 0 := by ext1; simpa only [hg] using hgp.coeff_zero x,
--   have h3 : p 1 = 0 := by { ext1; simp [h1] },
--   rw [formal_multilinear_series.order_eq_find' hp, nat.le_find_iff],
--   rintro n hn,
--   cases n, { simp only [h2, pi.zero_apply, ne.def, eq_self_iff_true, not_true, not_false_iff] },
--   cases n, { simp only [h3, pi.zero_apply, ne.def, eq_self_iff_true, not_true, not_false_iff] },
--   cases not_le.2 hn (nat.succ_le_succ (nat.succ_le_succ (nat.zero_le n)))
-- end

-- lemma tendsto_uniformly_on_add_const :
--   tendsto_uniformly_on (λ (ε z : ℂ), g z + ε) g (𝓝[≠] 0) U :=
-- begin
--   have : tendsto id (𝓝[≠] (0 : ℂ)) (𝓝 0) := nhds_within_le_nhds,
--   have : tendsto_uniformly_on (λ (ε z : ℂ), ε) 0 (𝓝[≠] 0) U := this.tendsto_uniformly_on_const U,
--   simpa using tendsto_uniformly_on_const.add this
-- end

-- lemma deriv_ne_zero_of_inj_aux (hU : IsOpen U) (hg : DifferentiableOn ℂ g U) (hi : inj_on g U)
--   (hz₀ : z₀ ∈ U) (hgz₀ : g z₀ = 0) :
--   deriv g z₀ ≠ 0 :=
-- begin
--   obtain ⟨p, hp⟩ : analytic_at ℂ g z₀ := hg.analytic_at (hU.mem_nhds hz₀),
--   have h25 : ∀ᶠ z in 𝓝[≠] z₀, g z ≠ 0,
--   { simp only [eventually_nhds_within_iff],
--     filter_upwards [hU.eventually_mem hz₀] with z hz hzz₀,
--     simpa only [hgz₀] using hi.ne hz hz₀ hzz₀ },
--   have h17 : p ≠ 0,
--     by simpa [← hp.locally_zero_iff.not] using h25.frequently.filter_mono nhds_within_le_nhds,
--   by_contra,
--   have h6 : 2 ≤ p.order := two_le_order_of_deriv_eq_zero hp h17 hgz₀ h,
--   obtain ⟨r, h7, h8, h14, h21, h20⟩ : ∃ r > 0,
--     cindex z₀ r g = p.order ∧
--     (∀ z ∈ ClosedBall z₀ r, z ≠ z₀ → deriv g z ≠ 0) ∧
--     (∀ z ∈ ClosedBall z₀ r, z ≠ z₀ → g z ≠ 0) ∧
--     ClosedBall z₀ r ⊆ U,
--   { obtain ⟨q, hq⟩ : analytic_at ℂ (deriv g) z₀ := (hg.deriv hU).analytic_at (hU.mem_nhds hz₀),
--     have h26 : q ≠ 0,
--     { rintro rfl,
--       simpa [hgz₀] using ((bla ⟨p, hp⟩ hq).filter_mono nhds_within_le_nhds).and h25 },
--     have e1 := cindex_eventually_eq_order hp,
--     have e2 := hp.locally_ne_zero h17,
--     have e3 := hq.locally_ne_zero h26,
--     have e4 := hU.eventually_mem hz₀,
--     simp only [eventually_nhds_within_iff, mem_compl_singleton_iff] at e2 e3,
--     simp only [eventually_nhds_iff_eventually_ClosedBall] at e2 e3 e4,
--     exact (e1.and (e3.and (e2.and e4))).exists' },
--   have h22 : ∀ z ∈ sphere z₀ r, g z ≠ 0,
--     from λ z hz, h21 z (sphere_subset_ClosedBall hz) (ne_of_mem_sphere hz h7.lt.ne.symm),
--   have h18 : ∀ ε, DifferentiableOn ℂ (λ z, g z + ε) U := λ ε, hg.add_const ε,
--   have h19 : tendsto_locally_uniformly_on (λ ε z, g z + ε) g (𝓝[≠] 0) U,
--     from tendsto_uniformly_on_add_const.tendsto_locally_uniformly_on,
--   have h9 : ∀ᶠ ε in 𝓝[≠] 0, cindex z₀ r (λ z, g z + ε) = 1,
--   { have h24 : p.order ≠ 0 := by linarith,
--     have := hurwitz2 hU (eventually_of_forall h18) h19 h7 h20 h22 (by simp [h8, h24]),
--     simp only [eventually_nhds_within_iff] at this ⊢,
--     filter_upwards [this] with ε h hε,
--     obtain ⟨z, hz, hgz⟩ := h hε,
--     have e1 : z ≠ z₀ := by { rintro rfl; rw [hgz₀, zero_add] at hgz; exact hε hgz },
--     have e2 : deriv (λ z, g z + ε) z ≠ 0 := by simpa using h14 z (ball_subset_ClosedBall hz) e1,
--     refine crucial hU h20 hz (h18 ε) hgz e2 (λ w hw hwz, _),
--     contrapose! hwz,
--     exact hi (h20 hw) ((ball_subset_ClosedBall.trans h20) hz) (add_right_cancel (hwz.trans hgz.symm)) },
--   have h10 : tendsto (λ ε, cindex z₀ r (λ z, g z + ε)) (𝓝[≠] 0) (𝓝 (cindex z₀ r g)),
--     from hurwitz2_2 hU (eventually_of_forall h18) h19 h7 (sphere_subset_ClosedBall.trans h20) h22,
--   rw [tendsto_nhds_unique (tendsto.congr' h9 h10) tendsto_const_nhds] at h8,
--   norm_cast at h8; linarith
-- end

-- lemma deriv_ne_zero_of_inj (hU : IsOpen U) (hf : DifferentiableOn ℂ f U) (hi : inj_on f U)
--   (hz₀ : z₀ ∈ U) :
--   deriv f z₀ ≠ 0 :=
-- begin
--   have : inj_on (λ z, f z - f z₀) U := λ z₁ hz₁ z₂ hz₂ h, hi hz₁ hz₂ (sub_left_inj.1 h),
--   simpa [deriv_sub_const] using deriv_ne_zero_of_inj_aux hU (hf.sub_const _) this hz₀ (sub_self _)
-- end