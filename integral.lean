import Mathlib

open List Finset BigOperators Function Metric WithBot

namespace Finset

variable [LinearOrder α]

@[simp] lemma min_union {s t : Finset α} : (s ∪ t).min = s.min ⊓ t.min := by
  simp [min_eq_inf_withTop, inf_union]

@[simp] lemma max_union {s t : Finset α} : (s ∪ t).max = s.max ⊔ t.max := by
  simp [max_eq_sup_withBot, sup_union]

@[simp] lemma min_toFinset {l : List α} : l.toFinset.min = l.minimum := by
  induction l with
  | nil => simp
  | cons a l ih => simp [ih, List.minimum_cons]

@[simp] lemma max_toFinset {l : List α} : l.toFinset.max = l.maximum := by
  induction l with
  | nil => rfl
  | cons a l ih => simp [ih, List.maximum_cons]

end Finset

namespace List

def pairs (l : List α) : List (α × α) := List.zip l l.tail

def progression (a δ : ℝ) : ℕ → List ℝ
| 0 => [a]
| n+1 => a :: List.progression (a + δ) δ n

lemma minimum_progression (h : 0 ≤ δ) : (progression a δ n).minimum = a := by
  induction n generalizing a with
  | zero => rfl
  | succ n ih => simp [progression, minimum_cons, ih, h]

lemma toto (h : 0 ≤ δ) : ∀ x ∈ progression a δ n, a ≤ x := by
  induction n generalizing a with
  | zero => simp [progression]
  | succ n ih =>
    simp [progression]
    intro x hx
    linarith [ih x hx]

lemma maximum_progression (h : 0 ≤ δ) : (progression a δ n).maximum = a + n * δ := by
  induction n generalizing a with
  | zero => simp [progression]
  | succ n ih =>
    simp only [progression, maximum_cons, ih, Nat.cast_succ]
    have e1 : (1 : WithBot ℝ) = ((1 : ℕ) : ℝ) := by norm_cast
    have e2 : (n : WithBot ℝ) = (n : ℝ) := by norm_cast
    have e3 : 0 ≤ (n : ℝ) := n.cast_nonneg
    convert max_eq_right ?_ using 1
    · simp only [e1, e2, ← WithBot.coe_mul, ← WithBot.coe_add, WithBot.coe_eq_coe]
      ring
    · simp only [e1, e2, ← WithBot.coe_mul, ← WithBot.coe_add, WithBot.coe_le_coe]
      nlinarith [e3]

end List

--

abbrev subd (a b : ℝ) := { s : Finset ℝ // s.min = a ∧ s.max = b }

structure subdivides (s : Finset ℝ) (a b : ℝ) : Prop where
  nonempty : s.Nonempty
  min : s.min' nonempty = a
  max : s.max' nonempty = b

abbrev subd' (a b : ℝ) := { s : Finset ℝ // subdivides s a b }

noncomputable def subdsubd : subd a b ≃ subd' a b where
  toFun := by
    rintro ⟨s, ha, hb⟩
    refine ⟨s, ?_, ?_, ?_⟩
    · by_contra h
      rw [Finset.min_eq_top.mpr (not_nonempty_iff_eq_empty.mp h)] at ha
      contradiction
    · rw [← WithBot.coe_inj]
      convert Finset.coe_min' _
      exact ha.symm
    · rw [← WithBot.coe_inj]
      convert Finset.coe_max' _
      exact hb.symm
  invFun := by
    rintro ⟨s, h0, ha, hb⟩
    refine ⟨s, ?_, ?_⟩
    · rw [← Finset.coe_min' h0, ha]
    · rw [← Finset.coe_max' h0, hb]
  left_inv := by rintro ⟨s, h1, h2⟩; simp
  right_inv := by rintro ⟨s, h1, h2, h3⟩; simp

noncomputable instance : Sup (subd a b) where
  sup := λ s t => ⟨s ∪ t, by simp [s.prop, t.prop]⟩

instance : Membership ℝ (subd a b) := ⟨λ x σ => x ∈ σ.val⟩

namespace subd

variable {a b : ℝ} {n : ℕ} {σ : subd a b}

noncomputable def ofList (l : List ℝ) (ha : l.minimum = a) (hb : l.maximum = b) : subd a b :=
  ⟨l.toFinset, by simp [ha, hb]⟩

noncomputable def regular (h : a ≤ b) (hn : 0 < n) : subd a b :=
  have h1 : 0 ≤ (b - a) / n := (div_nonneg (sub_nonneg_of_le h) (Nat.cast_nonneg n))
  have h2 : minimum (progression a ((b - a) / n) n) = a := minimum_progression h1
  have h3 : maximum (progression a ((b - a) / n) n) = b := by
    rw [maximum_progression h1]
    norm_cast
    rw [← WithBot.coe_add]
    field_simp [mul_comm, hn]
  ofList (List.progression a ((b - a) / n) n) h2 h3

def cast (σ : subd a b) (ha : a = a') (hb : b = b') : subd a' b' := ⟨σ, by simp [ha, hb, σ.prop]⟩

noncomputable def points (σ : subd a b) : List ℝ := σ.val.sort (· ≤ ·)

lemma one_lt_length (hab : a < b) : 1 < σ.points.length := by
  simp [points]
  have h1 := Finset.mem_of_min σ.prop.1
  have h2 := Finset.mem_of_max σ.prop.2
  rw [Finset.one_lt_card]
  refine ⟨a, h1, b, h2, ne_of_lt hab⟩

lemma points_subset {σ : subd a b} : ∀ x ∈ σ.points, x ∈ Set.Icc a b := by
  simp [points]
  rintro x hx
  have e1 : a ≤ x := by simpa [σ.prop.1] using Finset.min_le hx
  have e2 : x ≤ b := by simpa [σ.prop.2] using Finset.le_max hx
  tauto

noncomputable def pairs (σ : subd a b) : List (ℝ × ℝ) := σ.points.pairs

lemma pos_length_pairs (hab : a < b) : 0 < σ.pairs.length := by
  simp [pairs, List.pairs, one_lt_length hab]

noncomputable def mesh (σ : subd a b) (hab : a < b) : ℝ :=
  (σ.pairs.map (λ p => |p.2 - p.1|)).maximum_of_length_pos (by simpa using pos_length_pairs hab)

variable [AddCommMonoid E] [SMul ℝ E]

noncomputable def RS (f : ℝ → E) (σ : subd a b) : E :=
  (σ.points.pairs.map (λ p => (p.2 - p.1) • f p.1)).sum

def adapted (σ : subd a b) (S : ι → Set ℝ) : Prop :=
  ∀ p ∈ pairs σ, ∃ i, Set.Icc p.1 p.2 ⊆ S i

lemma titi (hab : a < b) (h1 : ∀ i, IsOpen (S i)) (h2 : Set.Icc a b ⊆ ⋃ i, S i) :
    ∃ ε > 0, ∀ σ : subd a b, σ.mesh hab ≤ ε → adapted σ S := by
  obtain ⟨ε, hε, l1⟩ := lebesgue_number_lemma_of_metric isCompact_Icc h1 h2
  refine ⟨ε / 2, by linarith, ?_⟩
  intro σ hσ p hp
  have l5 := List.mem_zip hp
  have l4 : p.1 ∈ σ.points := l5.1
  have l2 : p.1 ∈ Set.Icc a b := points_subset _ l4
  obtain ⟨i, hi⟩ := l1 p.1 l2
  refine ⟨i, subset_trans ?_ hi⟩
  have l3 : Set.OrdConnected (ball p.fst ε) := (convex_ball ..).ordConnected
  refine Set.Icc_subset _ (mem_ball_self hε) ?_
  simp [ball, dist_eq_norm]
  have l6 : |p.2 - p.1| ∈ σ.pairs.map (λ p => |p.2 - p.1|) :=
    List.mem_map_of_mem (λ p : ℝ × ℝ => |p.2 - p.1|) hp
  have l7 := List.le_maximum_of_mem' l6
  have l8 : 0 < (List.map (fun p => |p.snd - p.fst|) (pairs σ)).length := by
    simpa using pos_length_pairs hab
  rw [← List.coe_maximum_of_length_pos l8] at l7
  have := (WithBot.coe_le_coe.mp l7).trans hσ
  linarith

end subd

-----------------------------

structure List.subdivides (l : List ℝ) (a b : ℝ) : Prop where
  nonempty : l ≠ []
  sorted : l.Sorted (· ≤ ·)
  nodup : l.Nodup
  first : l.head nonempty = a
  last : l.getLast nonempty = b

lemma List.Sorted.head_le {l : List ℝ} (hl : l.Sorted (· ≤ ·)) (hx : x ∈ l) :
    l.head (ne_nil_of_mem hx) ≤ x := by
  match l with
  | a :: as => cases hx with
    | head => rfl
    | tail e1 h => exact (sorted_cons.1 hl).1 _ h

lemma List.Sorted.le_last {l : List ℝ} (hl : l.Sorted (· ≤ ·)) (hx : x ∈ l) :
    x ≤ l.getLast (ne_nil_of_mem hx) := by
  induction l with
  | nil => cases hx
  | cons a as ih => cases hx with
    | head => match as with
      | [] => rfl
      | b :: bs => simpa only [getLast_cons_cons] using (sorted_cons.1 hl).1 _ (getLast_mem _)
    | tail e h => match as with
      | [] => cases h
      | _ :: _ => exact ih (sorted_cons.1 hl).2 h

abbrev subdivision (a b : ℝ) := { l : List ℝ // l.subdivides a b }

namespace subdivision

variable {a b x : ℝ} {σ : subdivision a b}

instance : Membership ℝ (subdivision a b) := ⟨λ x σ => x ∈ σ.val⟩

noncomputable instance : Sup (subdivision a b) := sorry

noncomputable def regular (h : a ≤ b) (hn : 0 < n) : subdivision a b := sorry

def cast (σ : subdivision a b) (ha : a = a') (hb : b = b') : subdivision a' b' :=
  ⟨σ, σ.prop.nonempty, σ.prop.sorted, σ.prop.nodup, ha ▸ σ.prop.first, hb ▸ σ.prop.last⟩

lemma one_lt_length (hab : a < b) : 1 < (σ : List ℝ).length := by
  rcases σ with ⟨l, h1, h2, h3, h4, h5⟩ ; match l with
  | [_] => linarith [h4.symm.trans h5]
  | _ :: _ :: l => simp

noncomputable def pairs (σ : subdivision a b) : List (ℝ × ℝ) := (σ : List ℝ).pairs

lemma pos_length_pairs (hab : a < b) : 0 < σ.pairs.length := by
  simp [pairs, List.pairs, one_lt_length hab]

lemma subset (hx : x ∈ σ) : x ∈ Set.Icc a b := by
  rcases σ with ⟨l, h1, h2, h3, h4, h5⟩
  exact ⟨h4 ▸ h2.head_le hx, h5 ▸ h2.le_last hx⟩

noncomputable def mesh (σ : subdivision a b) : ℝ :=
  if h : a < b
  then (σ.pairs.map (λ p => |p.2 - p.1|)).maximum_of_length_pos (by simpa using pos_length_pairs h)
  else 0

lemma le_mesh (hab : a < b) (hp : p ∈ σ.pairs) : |p.2 - p.1| ≤ σ.mesh := by
  have h1 : |p.2 - p.1| ∈ σ.pairs.map (λ p => |p.2 - p.1|) :=
    List.mem_map_of_mem (λ p : ℝ × ℝ => |p.2 - p.1|) hp
  have h2 : 0 < (List.map (fun p => |p.snd - p.fst|) (pairs σ)).length := by
    simpa using pos_length_pairs hab
  simp only [mesh, hab]
  simpa only [← coe_maximum_of_length_pos h2, coe_le_coe] using le_maximum_of_mem' h1

def adapted (σ : subdivision a b) (S : ι → Set ℝ) : Prop :=
  ∀ p ∈ σ.pairs, ∃ i, Set.Icc p.1 p.2 ⊆ S i

lemma adapted_of_mesh_lt (hab : a < b) (h1 : ∀ i, IsOpen (S i)) (h2 : Set.Icc a b ⊆ ⋃ i, S i) :
    ∃ ε > 0, ∀ σ : subdivision a b, σ.mesh < ε → adapted σ S := by
  obtain ⟨ε, hε, l1⟩ := lebesgue_number_lemma_of_metric isCompact_Icc h1 h2
  refine ⟨ε, hε, λ σ hσ p hp => ?_⟩
  have : Set.OrdConnected (ball p.1 ε) := (convex_ball ..).ordConnected
  obtain ⟨i, hi⟩ := l1 p.1 (subset (List.mem_zip hp).1)
  exact ⟨i, subset_trans (Set.Icc_subset _ (mem_ball_self hε) ((le_mesh hab hp).trans_lt hσ)) hi⟩

-- lemma toto (hab : a ≤ b) (h1 : ∀ i, IsOpen (S i)) (h2 : Set.Icc a b ⊆ ⋃ i, S i) :
--     ∃ σ : subd a b, adapted σ S := by
--   obtain ⟨ε, hε, l1⟩ := lebesgue_number_lemma_of_metric isCompact_Icc h1 h2
--   sorry

end subdivision