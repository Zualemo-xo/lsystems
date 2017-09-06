module Lsystem.Generator
(
    step
  , walk
) where

import qualified System.Random as SR
import Control.Applicative
import Data.Maybe

import Lsystem.Grammar

firstSuccess :: (a -> Maybe b) -> [a] -> Maybe b
firstSuccess f xs = listToMaybe . mapMaybe f $ xs

choose :: Chance -> [(Chance, a)] -> Maybe (Chance, a)
choose p rs = firstSuccess (choose' p) (cumulative 0 rs) where

    cumulative :: Chance -> [(Chance, a)] -> [(Chance, Chance, a)]
    cumulative _ [] = [] 
    cumulative p ((q, x):qs) = [(p + q, q, x)] ++ cumulative (p + q) qs

    choose' :: Chance -> (Chance, Chance, a) -> Maybe (Chance, a)
    choose' p (c, q, x)
      -- p : random bernoulli variable
      -- q : the rule's absolute probability
      -- c : the rule's cumulative probability
      | p < 0 || p > 1 = error "Invalid random generator: probability values must be between 0 and 1"
      | c < 0 || c > 1 = error "Invalid stochastic rule: probability must be between 0 and 1"
      | p <= c = Just (q, x)
      | otherwise = Nothing

applyRules :: SR.StdGen -> LeftContext -> RightContext -> [Rule] -> Node -> [Node]
applyRules _ _  _  []     n = [n]
applyRules g lc rc rs n = fromMaybe [n] . firstSuccess (applyRule p) $ rs
  where
    p :: Double
    p = fst $ SR.randomR (0.0,1.0) g

    applyRule :: Chance -> Rule -> Maybe [Node]
    applyRule _ (DeterministicRule cont cond match repl) =
      return repl        -- replace node if:
        >>= match n      -- * the node is of the correct form
        >>= cont lc rc   -- * it is in the required context
        >>= cond lc rc n -- * all parametric restrictions are met
    applyRule p (StochasticRule rs') = case (choose p rs') of
      -- p is rescaled by dividing by the selected rule's probability
      Just (cp', r) -> applyRule (p / cp') r
      _ -> Nothing

rContextMap :: SR.StdGen -> (SR.StdGen -> [a] -> [a] -> a -> b) -> [a] -> [a] -> [b]
rContextMap _ _ _ [] = []
rContextMap g f lc (r:rc) = [f g lc rc r] ++ rContextMap (snd $ SR.next g) f (r:lc) rc

rMap :: SR.StdGen -> (SR.StdGen -> a -> b) -> [a] -> [b]
rMap _ _ [] = []
rMap g f (x:xs) = [f g x] ++ rMap (snd $ SR.next g) f xs

step :: [Rule] -> SR.StdGen -> [Node] -> [Node] -> Node -> [Node]
step rs g lc rc (NodeBranch nss) = [NodeBranch (rMap (fst $ SR.split g) desc' nss)] where
  desc' :: SR.StdGen -> [Node] -> [Node]
  desc' g' xs = concat . rContextMap g' (step rs) lc $ xs
step rs g lc rc r = applyRules g lc rc rs r

walk :: [Rule] -> SR.StdGen -> [Node] -> [[Node]]
walk rs g ns = [ns] ++ walk' rs g ns where
  walk' rs g' ns = [next'] ++ future' where
    gs      = SR.split g'
    next'   = concat $ rContextMap (fst gs) (step rs) [] ns
    future' = walk' rs (snd gs) next'






-- data W = W {
--       wGen :: SR.StdGen
--     , wLeft :: [Node]
--     , wRight :: [Node]
--     , wRule :: [Rule]
--     , wNextGen :: [Node]
--   }
--
-- emptyW :: W = W {
--       wGen     = SR.mkStdGen 0
--     , wLeft    = []
--     , wRight   = []
--     , wRule    = []
--     , wNextGen = []
--   }
--
-- initW :: Int -> System -> W
-- initW seed (System _ []  _) = emptyW { wGen = SR.mkStdGen seed }
-- initW seed (System ns rs _) = emptyW {
--       wGen     = SR.mkStdGen seed
--     , wRight   = ns
--     , wRule    = rs
--   }
--
-- branchSplit :: W -> [[Node]] -> [W]
-- branchSplit _ [] = []
-- branchSplit (ns:nss) w = case (splitW w) of
--   (w1, w2) -> [w1 {wRight = ns}] ++ branchSplit w2
--
-- walk :: W -> [Node]
-- walk = undefined
--
-- splitW :: W -> (W,W)
-- splitW w -> case (SR.split $ wGen w) of
--   (g1, g2) -> (w {wGen=g1}, w{wGen=g2})
--
-- wNextGen :: W -> Maybe W
-- wNextGen (W _ _  [] _ _) = Nothing
-- wNextGen (W g lc (r:rc) rs ngs) = Just $
--   W {
--       wGen = snd $ SR.next g
--     , wLeft = r:lc
--     , wRight = rc
--     , wRules = rs
--     , wNextGen = ngs
--   }
--
-- step :: W -> W
-- step w = case wCurrent w of
--   NodeBranch nss -> zip nss (multiplyGen (wGen w))
--
-- getRule :: W -> Rule
--
-- applyRule :: Rule -> W -> W
--
--
-- -- step :: W -> Maybe W
-- -- step (W _   _  [] _ _ ) -> Nothing
-- -- step (W gen lc rc (NodeBranch nss) rs) -> undefined
-- -- step (W gen lc rc c rs) -> undefined
-- --
-- --
-- -- mkBranch :: W -> [[Node]] -> W
-- -- mkBranch w nss = w {wGen = g', wLeft =
-- --
-- -- mkBranch w [] = w
-- -- mkBranch (W gen lc rc c rs) nss = W {
-- --       wGen :: SR.StdGen
-- --     , wLeft :: [Node]
-- --     , wRight :: [Node]
-- --     , wCurrent :: Node
-- --     , wRule :: [Rule]
-- --   }
--
--
--
--
