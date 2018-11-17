functor MkDivideAndConquerPD (structure P : PAREN_PACKAGE) : PAREN_DIST =
struct
  structure P = P
  open Primitives
  open P
  open Seq
  open Option210

  (* parenDist : paren seq
    *   -> int option
    * 1. divide the input paren seq into a tree.
    * 2. calculate using the function `pd`.(see details in the function pd)
    * 3. return first part of the result of `pd`, or NONE when it equals to SOME 0
    *)
  fun parenDist (parens : paren seq) : int option =
    let
      (* getValue : int option
        *   -> int
        * get the value of a optional variable
        * get an error when using NONE as an input!!!
        * should only be used to print debug messages!!!
        *)
      fun getValue (option) =
            let
              val SOME(value) = option
            in value end
      
      (* pd : paren seq
        *   -> (int option * int * int * int * int * int)
        * @s0 : input paren seq
        * @max(maximum length) : maximum length of matched paren seq so far.
        * @closed(maximum closed length) : the length of the longest `closed` paren seq.
        * |   1. consists of one continuous matched paren seq, can not be separately matched , e.g. the @closed of "()()(())(" is 4 instead of 8
          |   2. has no right paren #")" next to its right, no left paren #"(" next to its left.)
        * @lo(left open number) : number of unclosed left paren #"(".
        * @ro(right open number) : number of unclosed right paren #")".
        * @ld(left distance) : maximum distance for an unclosed right paren #")" to the left boundary.
        * @rd(right distance) : maximum distance for an unclosed left paren #"(" to the right boundary.
        * 
        * steps:
        *   1. split the paren seq using `showt` recursely, for each recursion, calculate both subtree in parallel, and save the params needed from both side of subtrees.
        *   2. notice two point:
        *    |  2.1. a tree's length strictly equals to its `rd+ld+closed`.
        *    |  2.2. a tree can only have one `closed` part, or the part between two closed part should also be closed by a #"(" and a #")" according to the definition of @closed.
        *   3. judge whether left subtree's lo (`llo`) or right subtree's ro (`rro`) is larger, save the difference into `curopen = llo-rro`.
        *    |  3.1. if `llo` is larger:
        *    |   |  3.1.1. obviously, the new @closed equals to left subtree's @closed (`closed=lclosed`), because it has an unclosed #"(" next to its right, excluding all the right part to be `closed`.
        *    |   |  3.1.2. max is simply the record of whether the @max of both subtrees, the @closed of the cmerged one, or the recently merged and matched part, maybe unconfirmed to the second restrict of `closed`, is larger. That is `max = maxium(lmax, rmax, closed, 2*minimum(lrd, rld)).`
        *    |   |  3.1.3. the new @lo equals to all the remained llo after the merge, together with the `rlo` that do nothing during the merge, the result is `lo=curopen+rlo`.
        *    |   |  3.1.4. because there is no ro on the right part (all closed by `llo` when merged), obviously the new @ro equals to the left subtree's @ro (`ro=lro`).
        *    |   |  3.1.5. having no relation to the merge, the new @ld equals to the left subtree's @ld (`ld=lld`).
        *    |   |  3.1.6. the new @rd equals to the sum of left subtree's @rd (`lrd`) and the whole right tree, that is `rd=lrd+rld+rrd+rclosed` according to step `2.1`.
        *    |  2. if `rro` is larger:
        *    |   |  3.2.1. simply change all the 'l' and 'r' in step `3`, notice that `curopen` should be changed to `~curopen`
        *    |  3. if `llo` equals to `rro`:
        *    |   |  3.3.1. @closed should be `max(lclosed, rclosed, lrd+rld)` because in this case, the recently merged part (`lrd+rld`) is also `closed`.
        *    |   |  3.3.2. @max as shown in former cases.
        *    |   |  3.3.3. @ro equals `lro`, similar to step `3.1.4`.
        *    |   |  3.3.4. @lo equals to `rlo`, combining step `3.3.3` and `3.2.1`.
        *    |   |  3.3.5. @ld equals to `lld`, similar to step `3.1.5`.
        *    |   |  3.3.6. @rd equals to `rrd`, combining step `3.3.5` and `3.2.1`.
        *   4. return (@max, @closed, @lo, @ro, @ld, @rd)

        *)
      fun pd (s0) : (int option * int * int * int * int * int) =
        case showt s0
          of EMPTY => (SOME 0, 0, 0, 0, 0, 0)
           | ELT OPAREN => (SOME 0, 0, 1, 0, 0, 1)
           | ELT CPAREN => (SOME 0, 0, 0, 1, 1, 0)
           | NODE (sl, sr) => 
            let
              val ((lmax, lclosed, llo, lro, lld, lrd), (rmax, rclosed, rlo, rro, rld, rrd)) = par (fn _ => pd sl, fn _ => pd sr)
              (* val pl = print("lclosed:"^Int.toString (getValue lmax)^","^Int.toString lclosed^"("^Int.toString(llo)^","^Int.toString(lro)^","^Int.toString(lld)^","^Int.toString(lrd)^")\n")
              val pr = print("rclosed:"^Int.toString (getValue rmax)^","^Int.toString rclosed^"("^Int.toString(rlo)^","^Int.toString(rro)^","^Int.toString(rld)^","^Int.toString(rrd)^")\n") *)
              val curopen = llo - rro
              val closed = if curopen > 0 then lclosed
                else if curopen < 0 then rclosed
                else iter Int.max 0 (Seq.fromList [lclosed, rclosed, lrd+rld])
              val max = iter Option210.intMax (SOME 0) (Seq.fromList [lmax, rmax, SOME closed, SOME (2 * Int.min (lrd,rld))])
              val lo = if curopen > 0 then curopen+rlo else rlo
              val ro = if curopen < 0 then (~curopen)+lro else lro
              val ld = if curopen < 0 then rld+(lld+lrd+lclosed) else lld
              val rd = if curopen > 0 then lrd+(rld+rrd+rclosed) else rrd
              (* val p = print("closed:"^Int.toString (getValue max)^","^Int.toString closed^"("^Int.toString(lo)^","^Int.toString(ro)^","^Int.toString(ld)^","^Int.toString(rd)^")\n") *)
            in
              (max, closed, lo, ro, ld, rd)
            end

      val (max, _, _, _, _, _) = pd parens
    in
      if max = SOME 0 then NONE else max
    end

end
