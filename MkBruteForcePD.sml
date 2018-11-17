functor MkBruteForcePD (structure P : PAREN_PACKAGE) : PAREN_DIST =
struct
  structure P = P
  open P
  open Seq
  open Option210


  
  (* parenDist : paren seq
    *   -> int option
    * 1. using `findSub` to go through all subsequences of the input paren seq, saved into a list called `subs`.
    * 2. using `check` to save all that contain and only contain one matched paren seq into a list called `allows`.
    * 3. using `parenlengths` to turn all the allowed subseqs into the list of their lengths.
    * 4. find the max among all the allowed lengths, return the maxmium length, or NONE when the max is 0.
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

      (* parenMatch : paren seq
        *   -> bool
        * This function returns true whenever a paren seq contains and only contains one matched paren seq, without having any other paren.
        *)
      fun parenMatch (parens : paren seq) : bool =
        let
          (* pm : (int list * int * int) * (int * paren)
            *   -> (int list * int * int)
            * This function is used to help check whether only one matched paren seq is contained
            *)
          fun pm (([], flag, num), (_, CPAREN)) = ([], flag, NONE) (* break *)
            | pm ((j::opens, flag, num), (i, CPAREN)) = (opens, flag-1, num)
            | pm ((opens, flag, num), (i, OPAREN)) = 
              (* value won't be NONE unless the first case happens and the function breaks *)
              if flag = 0 then (
                i::opens, 
                flag+1, 
                if num = NONE then NONE 
                else 
                  let 
                    val SOME (value) = num 
                  in 
                    SOME(value + 1) 
                  end
              ) 
              else (i::opens, flag+1, num)
              
          val (_, result, pairs) = iter pm ([], 0, SOME 0) (enum parens)
        in
          if result = 0 andalso pairs = SOME 1 then true else false
        end
      
      (* parenMatch : (parens * int * int * paren seq list)
        *   -> paren seq list
        * recursionally check all the subsequences of a paren.
        *)
      fun findSub (parens, i, len, parenlist) : paren seq list = 
        let
          val total = Seq.length parens
        in
          if len = total then parens::parenlist
          else if i+len-total = 0 then (Seq.subseq parens (i, len)) :: findSub(parens, 0, len+1, parenlist) else (Seq.subseq parens (i, len)) :: findSub(parens, i+1, len, parenlist) 
        end

      val subs = findSub(parens, 0, 0,[])

      (* check : paren seq list
        *   -> paren seq list
        * save all subseqs that contains and only contains one matched parens. other subseqs will be removed.
        *)
      fun check (j::todos) = 
        if parenMatch j then j::check(todos) else check(todos)
        | check (todos) = todos
      
      val allows = check subs

      (* parenLength : (int option * paren seq)
        *   -> paren seq list
        * turn a list of parens into a list of their lengths.
        *)
      fun parenLength (curlengths, paren) = 
        (SOME (Seq.length paren))::curlengths

      val lengths = iter parenLength [] (Seq.fromList allows)
      val result = iter intMax (SOME 0) (Seq.fromList lengths)
    in
      if result = SOME 0 then NONE else result
    end
      

end
