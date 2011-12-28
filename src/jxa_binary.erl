%% -*- mode: Erlang; fill-column: 80; comment-column: 76; -*-
-module(jxa_binary).

-export([comp/3, comp_pattern/3]).
-include_lib("joxa/include/joxa.hrl").

-record(bitstring, {var, size, unit, type=integer,
                    signedness=unsigned,
                    endianness=big}).

%%=============================================================================
%% Public API
%%=============================================================================
comp(Path0, Ctx0, [binary | Args]) ->
    {_, {Line, _}} = jxa_annot:get(jxa_path:path(Path0),
                                   jxa_ctx:annots(Ctx0)),
    {Ctx1, Bitstrings} = mk_binary(jxa_path:incr(Path0), Ctx0, Args),
    {Ctx1, cerl:ann_c_binary([Line], Bitstrings)}.

comp_pattern(Path0, Acc0={Ctx0, _}, [binary | Args]) ->
    {_, {Line, _}} = jxa_annot:get(jxa_path:path(Path0),
                                   jxa_ctx:annots(Ctx0)),
    {Acc1, Bitstrings} = mk_pattern_binary(jxa_path:incr(Path0), Acc0, Args),
    {Acc1, cerl:ann_c_binary([Line], Bitstrings)}.

%%=============================================================================
%% Private Functions
%%=============================================================================
mk_pattern_binary(Path0, Acc0, Args) ->
    {_, Acc3, BSAcc} =
        lists:foldl(fun([Var | Pairs0], {Path1, Acc1={Ctx0, _}, BSAcc}) ->
                            Path2 = jxa_path:add(Path1),
                            {_, Idx={Line, _}} =
                                jxa_annot:get(jxa_path:add_path(Path2),
                                              jxa_ctx:annots(Ctx0)),
                            {{Ctx1, PG}, CerlVar} =
                                 jxa_clause:comp_pattern(Path2, Acc1, Var),
                             Desc = resolve_defaults(
                                      convert(Pairs0,
                                              #bitstring{var=CerlVar})),
                             case Desc of
                                 invalid ->
                                     ?JXA_THROW({invalid_bistring_spec, Idx});
                                 _ ->
                                     ok
                             end,

                             {Ctx2, Size} =
                                jxa_expression:comp(Path2,
                                                    Ctx1,
                                                    Desc#bitstring.size),
                             Unit = cerl:ann_c_int([Line],
                                                   Desc#bitstring.unit),
                             Type = cerl:ann_c_atom([Line],
                                                    Desc#bitstring.type),
                             Flags =
                                 cerl:ann_make_list([Line],
                                                    [cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.signedness),
                                                     cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.endianness)]),


                            {jxa_path:incr(Path1),
                             {Ctx2, PG},
                             [cerl:ann_c_bitstr([Line],
                                                Desc#bitstring.var,
                                                Size,
                                                Unit,
                                                Type,
                                                Flags) | BSAcc]};
                       (Var, {Path1, Acc1={Ctx0, _}, BSAcc})
                          when is_atom(Var) orelse is_integer(Var) ->
                            {_, Idx={Line, _}} =
                                jxa_annot:get(jxa_path:add_path(Path1),
                                              jxa_ctx:annots(Ctx0)),
                            {{Ctx1, PG}, CerlVar} =
                                 jxa_clause:comp_pattern(Path1, Acc1,
                                                         Var),
                             Desc = resolve_defaults(#bitstring{var=CerlVar}),
                             case Desc of
                                 invalid ->
                                     ?JXA_THROW({invalid_bistring_spec, Idx});
                                 _ ->
                                     ok
                             end,

                             {Ctx2, Size} =
                                jxa_expression:comp(Path1,
                                                    Ctx1,
                                                    Desc#bitstring.size),
                             Unit = cerl:ann_c_int([Line],
                                                   Desc#bitstring.unit),
                             Type = cerl:ann_c_atom([Line],
                                                    Desc#bitstring.type),
                             Flags =
                                 cerl:ann_make_list([Line],
                                                    [cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.signedness),
                                                     cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.endianness)]),
                            {jxa_path:incr(Path1),
                             {Ctx2, PG},
                             [cerl:ann_c_bitstr([Line],
                                                Desc#bitstring.var,
                                                Size,
                                                Unit,
                                                Type,
                                                Flags) | BSAcc]};
                       (_, {Path1, {Ctx0, _}, _Acc}) ->
                            {_, Idx} =
                                jxa_annot:get(jxa_path:add_path(Path1),
                                              jxa_ctx:annots(Ctx0)),
                            ?JXA_THROW({invalid_bitstring, Idx})
                    end,
                    {Path0, Acc0, []},
                    Args),
    {Acc3, lists:reverse(BSAcc)}.


mk_binary(Path0, Ctx0, Args) ->
    {_, Ctx3, Acc} =
        lists:foldl(fun([Var | Pairs0], {Path1, Ctx1, Acc}) ->
                            Path2 = jxa_path:add(Path1),
                            {_, Idx={Line, _}} =
                                jxa_annot:get(jxa_path:add_path(Path2),
                                              jxa_ctx:annots(Ctx0)),
                            {Ctx2, CerlVar} =
                                 jxa_expression:comp(Path2, Ctx1, Var),
                             Desc = resolve_defaults(
                                      convert(Pairs0,
                                              #bitstring{var=CerlVar})),
                             case Desc of
                                 invalid ->
                                     ?JXA_THROW({invalid_bistring_spec, Idx});
                                 _ ->
                                     ok
                             end,

                             {Ctx3, Size} =
                                jxa_expression:comp(Path2,
                                                    Ctx2,
                                                    Desc#bitstring.size),
                             Unit = cerl:ann_c_int([Line],
                                                   Desc#bitstring.unit),
                             Type = cerl:ann_c_atom([Line],
                                                    Desc#bitstring.type),
                             Flags =
                                 cerl:ann_make_list([Line],
                                                    [cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.signedness),
                                                     cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.endianness)]),


                            {jxa_path:incr(Path2),
                             Ctx3,
                             [cerl:ann_c_bitstr([Line],
                                                Desc#bitstring.var,
                                                Size,
                                                Unit,
                                                Type,
                                                Flags) | Acc]};
                       (Var, {Path1, Ctx1, Acc})
                            when is_atom(Var) orelse is_integer(Var) ->
                            {_, Idx={Line, _}} =
                                jxa_annot:get(jxa_path:add_path(Path1),
                                              jxa_ctx:annots(Ctx0)),
                            {Ctx2, CerlVar} =
                                 jxa_expression:comp(Path1, Ctx1, Var),
                             Desc = resolve_defaults(#bitstring{var=CerlVar}),
                             case Desc of
                                 invalid ->
                                     ?JXA_THROW({invalid_bistring_spec, Idx});
                                 _ ->
                                     ok
                             end,

                             {Ctx3, Size} =
                                jxa_expression:comp(Path1,
                                                    Ctx2,
                                                    Desc#bitstring.size),
                             Unit = cerl:ann_c_int([Line],
                                                   Desc#bitstring.unit),
                             Type = cerl:ann_c_atom([Line],
                                                    Desc#bitstring.type),
                             Flags =
                                 cerl:ann_make_list([Line],
                                                    [cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.signedness),
                                                     cerl:ann_c_atom([Line],
                                                                     Desc#bitstring.endianness)]),


                            {jxa_path:incr(Path1),
                             Ctx3,
                             [cerl:ann_c_bitstr([Line],
                                                Desc#bitstring.var,
                                                Size,
                                                Unit,
                                                Type,
                                                Flags) | Acc]};

                       (_, {Path1, _Ctx1, _Acc}) ->
                            {_, Idx} =
                                jxa_annot:get(jxa_path:add_path(Path1),
                                              jxa_ctx:annots(Ctx0)),
                            ?JXA_THROW({invalid_bitstring, Idx})
                    end,
                    {Path0, Ctx0, []},
                    Args),
    {Ctx3, lists:reverse(Acc)}.

resolve_defaults(invalid) ->
    invalid;
resolve_defaults(Bitstring=#bitstring{size=Size0, unit=Unit0, type=Type}) ->
   Size1 = case Size0 of
               undefined ->
                   case Type of
                       integer ->
                           8;
                       float ->
                           64;
                       binary ->
                           [quote, all];
                       bitstring ->
                           1;
                       bits ->
                           1
                   end;
               Value0 ->
                   Value0
           end,
    Unit1 = case Unit0 of
                undefined ->
                    case Type of
                        float ->
                            1;
                        integer ->
                            1;
                        bitstring ->
                            1;
                        bits ->
                            1;
                        binary ->
                            8
                    end;
                Value1 ->
                    Value1
            end,
    Bitstring#bitstring{size=Size1, unit=Unit1}.

convert([], Bitstring) ->
    Bitstring;
convert([[quote, size], Value | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{size=Value});
convert([[quote, unit], Value | Rest], Bitstring) when is_integer(Value) ->
    convert(Rest, Bitstring#bitstring{unit=Value});
convert([[quote, little] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{endianness=little});
convert([[quote, big] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{endianness=big});
convert([[quote, native] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{endianness=native});
convert([[quote, signed] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{signedness=signed});
convert([[quote, unsigned] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{signedness=unsigned});
convert([[quote, integer] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{type=integer});
convert([[quote, binary] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{type=binary});
convert([[quote, float] | Rest], Bitstring) ->
    convert(Rest, Bitstring#bitstring{type=float});
convert(_, _Bitstring) ->
    invalid.





