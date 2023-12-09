import Mathlib.GroupTheory.PresentedGroup
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.GroupTheory.Subgroup.Basic
import Mathlib.Tactic.Linarith.Frontend


open Classical

variable {G : Type _} [Group G] {S: Set G}

section list_prop
@[simp]
lemma nil_eq_nil: (([]: List S) : List G) = [] := by rfl

@[simp]
lemma coe_cons {hd : S}  {tail : List S} : (Lean.Internal.coeM (hd::tail) : List G) = (hd : G) :: (Lean.Internal.coeM tail : List G) := by {
  rfl
}

@[simp]
lemma coe_append  {l1 l2: List S} : (Lean.Internal.coeM (l1 ++ l2): List G) = (Lean.Internal.coeM l1 : List G) ++ (Lean.Internal.coeM l2 : List G):= by {
  simp [Lean.Internal.coeM]
}

lemma mem_coe_list {x : G} {L : List S}: x ∈ (Lean.Internal.coeM L : List G) → x ∈ S := by {
  intro H
  induction L with
  | nil => trivial
  | cons hd tail ih => {
    rw [coe_cons,List.mem_cons] at H
    cases H with
    | inl hh => {simp [hh]}
    | inr hh => {exact ih hh}
  }
}

@[simp]
def List.gprod {S : Set G} (L : List S) := (L : List G).prod

lemma gprod_nil : @List.gprod G _ S [] = (1:G ):=by {exact List.prod_nil}

lemma gprod_singleton {s:S}: [s].gprod = s:=by rw [List.gprod,coe_cons, nil_eq_nil, List.prod_cons, List.prod_nil, mul_one]

lemma gprod_cons {hd : S}  {tail : List S} : (hd::tail).gprod = hd * (tail.gprod) := by {
  rw [List.gprod,List.gprod,<-List.prod_cons]
  congr
}

lemma gprod_append {l1 l2: List S} : (l1 ++ l2).gprod = l1.gprod * l2.gprod := by {
  rw [List.gprod,List.gprod,List.gprod,<-List.prod_append]
  congr
  simp [Lean.Internal.coeM]
}

lemma gprod_append_singleton {l1 : List S} {s : S}: (l1 ++ [s]).gprod = l1.gprod * s := by {
  rw [<-gprod_singleton,gprod_append]
}

lemma reverse_prod_prod_eq_one {L: List S}  : L.reverse.gprod * L.gprod = 1:=sorry

lemma gprod_reverse (L: List S) : L.reverse.gprod = (L.gprod)⁻¹ := by {
   simp only[List.gprod]
   rw [List.prod_inv_reverse]
   congr
   sorry
}

end list_prop




class orderTwoGen {G : Type _}[Group G] (S:outParam (Set G))where
  order_two :  ∀ (x:G) , x ∈ S →  x * x = (1 :G) ∧  x ≠ (1 :G)
  expression : ∀ (x:G) , ∃ (L : List S),  x = L.gprod

-- lemma eqSubsetProd [orderTwoGen S] (g : G) : ∃ (L : List S),
--    g = L.gprod := by {
--     have H:= @generating G A _ _ S _ g
--     exact @Subgroup.memClosure_if_Prod G A _ _ S _ g H
--    }

lemma inv_eq_self  [orderTwoGen S]: ∀ x:G,  x∈S → x = x⁻¹ :=
fun x hx => mul_eq_one_iff_eq_inv.1 (orderTwoGen.order_two x hx).1

lemma non_one [orderTwoGen S]: ∀ x:G,  x∈S → x ≠ 1 :=
fun x hx => (orderTwoGen.order_two x hx).2

lemma inv_eq_self'  [orderTwoGen S]: ∀ x:S,  x = (x:G)⁻¹ :=
by {
   intro x
   nth_rw 1 [inv_eq_self x.1 x.2]
}

def expressionSet (g:G) [orderTwoGen S]:= {L:List S| g = L.gprod}

#check List S
#check Set.Elem S
#check Set S
#check orderTwoGen

variable [orderTwoGen S]

lemma eqSubsetProd [orderTwoGen S] (g : G) : ∃ (L : List S),  g = L.gprod := by {
    have H:= @orderTwoGen.expression G  _ S _ g
    exact H
   }

@[simp]
def reduced_word (L : List S) [orderTwoGen S]:= ∀ (L' : List S),  L.gprod =  L'.gprod →  L.length ≤ L'.length

def length_aux (g : G) [orderTwoGen S]: ∃ (n:ℕ) , ∃ (L : List S), L.length = n ∧ g = L.gprod := by
  let ⟨L,hL⟩ := @orderTwoGen.expression G _ S _ g
  use L.length,L

#check length_aux

noncomputable def length (x : G): ℕ := Nat.find (@length_aux G _ S x _)

#check length


local notation :max "ℓ(" g ")" => (@length G  _ S _ g)

def T (S:Set G) [orderTwoGen S]:= {x:G| ∃ (w:G)(s:S) , x = w*(s:G)*w⁻¹}

def T_L (w:G):= {t ∈ T S | ℓ(t*w) < ℓ(w)}
def T_R (w:G):= {t ∈ T S | ℓ(w*t) < ℓ(w)}

def D_L (w:G):= T_L w ∩ S
def D_R (w:G):= T_R w ∩ S
#check T

lemma nonemptyD_L(v:G) (h:v ≠ 1) :Nonempty (D_L v):=sorry

lemma nonemptyD_R(v:G) (h:v ≠ 1) :Nonempty (D_R v):=sorry





def StrongExchangeProp:= ∀ (L:List S) (t: T S) ,ℓ(t*L.gprod) < ℓ(L.gprod) → ∃ (i:Fin L.length), t * L.gprod = (L.removeNth i).gprod

def ExchangeProp := ∀ (L:List S) (s:S) ,reduced_word L →
      ℓ((s * L.gprod)) ≤ ℓ(L.gprod) → ∃ (i: Fin L.length) ,s * L.gprod = (L.removeNth i).gprod

def DeletionProp := ∀ (L:List S),ℓ(L.gprod) < L.length → ∃ (j: Fin L.length), ∃ (i:Fin j), L.gprod = ((L.removeNth j).removeNth i).gprod


class CoxeterSystem (G : Type _) (S : Set G) [Group G] [orderTwoGen S] where
  exchange : @ExchangeProp G _ S _
  deletion : @DeletionProp G _ S _