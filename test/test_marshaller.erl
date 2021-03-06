%% Author: carl
%% Created: 02 Apr 2011
%% Description: TODO: Add description to test_marshaller
-module(test_marshaller).

%%
%% Include files%%
-include_lib("eunit/include/eunit.hrl").

%%
%% Exported Functions
%%
-export([unmarshal_mti/1, marshal_mti/1, marshal_field/3, 
		 marshal_bitmap/1, marshal_end/2, unmarshal_end/2, 
		 unmarshal_field/3, unmarshal_bitmap/1, unmarshal_init/2, 
		 marshal_init/1, arrange_fields/1]).

%%
%% API Functions
%%
marshal_field(_N, Value, erl8583_fields) ->
	Value;
marshal_field(_N, Value, foo_rules) ->
	<<"_", Value/binary>>;
marshal_field(_N, _Value, erl8583_fields_1993) ->
	<<"1993">>.

marshal_mti(<<"0200">>) ->
	<<0,2,0,0>>;
marshal_mti("0100") ->
	"0100";
marshal_mti(Value) ->
	Value.

marshal_bitmap(Message) ->
	[0, 2,3] = erl8583_message:get_fields(Message),
	{<<"bitmap = 123">>, erl8583_message:set(1, "1", Message)}.

marshal_end(_Message, Marshalled) ->
	<<"Start", Marshalled/binary, "End">>.

unmarshal_end(Message, _Marshalled) ->
	erl8583_message:remove(1, Message).

marshal_init(Message) ->
	{<<"X">>, erl8583_message:set(0, "0110", Message)}.

unmarshal_init(Message, Marshalled) ->
	MarshalledList = erlang:binary_to_list(Marshalled),
	{Message, erlang:list_to_binary(lists:sublist(MarshalledList, 2, length(MarshalledList)-2))}.

unmarshal_field(0, <<0,2,0,0,Rest/binary>>, _) ->
	{<<"0200">>, Rest, []};
unmarshal_field(10, <<10, Tail/binary>>, _) ->
	{<<10>>, Tail, []};
unmarshal_field(20, <<20, Tail/binary>>, _) ->
	{<<20>>, Tail, [30]};
unmarshal_field(30, <<30, Tail/binary>>, _) ->
	{<<30>>, Tail, []};
unmarshal_field(_, <<H,Rest/binary>>, _) ->
	{<<(H+$0)>>, Rest, []}.

unmarshal_bitmap(<<7,T/binary>>) ->
	{[1, 2, 3], T};
unmarshal_bitmap(<<31, T/binary>>) ->
	{[1, 2, 3, 4, 5], T};
unmarshal_bitmap(<<30, T/binary>>) ->
	{[10, 20], T}.

arrange_fields([1, 2, 3]) ->
	[2, 1, 3];
arrange_fields([10, 20]) ->
	[20, 10];
arrange_fields(Fields) ->
	Fields.

unmarshal_mti(Marshalled) ->
	{FieldValue, Rest, _Fields} = unmarshal_field(0, Marshalled, undefined),
	{FieldValue, Rest}.

no_encoders_test() ->
	Message = erl8583_message:new(),
	<<>> =  erl8583_marshaller:marshal(Message, []).
	
mti_test() ->
	Message = erl8583_message:set(0, "0200", erl8583_message:new()),
	<<0, 2, 0, 0>> = erl8583_marshaller:marshal(Message, [{field_marshaller, ?MODULE}, {mti_marshaller, ?MODULE}]).

bitmap_test() ->
	Message0 = erl8583_message:set(0, "0200", erl8583_message:new()),
	Message1 = erl8583_message:set(2, "1", Message0),	
	Message2 = erl8583_message:set(3, "1", Message1),
	<<"bitmap = 123">> = erl8583_marshaller:marshal(Message2, [{bitmap_marshaller, ?MODULE}]).

fields_test() ->
	Message0 = erl8583_message:set(0, "0100", erl8583_message:new()),
	Message1 = erl8583_message:set(1, "V1", Message0),
	Message2 = erl8583_message:set(2, "V2", Message1),	
	Message3 = erl8583_message:set(3, "V3", Message2),
	<<"0100V1V2V3">> = erl8583_marshaller:marshal(Message3, [{field_marshaller, ?MODULE}, {mti_marshaller, ?MODULE}]).
	
fields_with_encoding_rules_test() ->
	Message0 = erl8583_message:set(0, "0100", erl8583_message:new()),
	Message1 = erl8583_message:set(1, "V1", Message0),
	Message2 = erl8583_message:set(2, "V2", Message1),	
	Message3 = erl8583_message:set(3, "V3", Message2),
	Options = [{field_marshaller, ?MODULE}, {encoding_rules, foo_rules}, {mti_marshaller, ?MODULE}],
	<<"0100_V1_V2_V3">> = erl8583_marshaller:marshal(Message3, Options).

marshal_end_test() ->
	Message = erl8583_message:set(0, "0200", erl8583_message:new()),
	Options = [{field_marshaller, ?MODULE}, {end_marshaller, ?MODULE}, {mti_marshaller, ?MODULE}],
	<<"Start", 0, 2, 0, 0, "End">> = erl8583_marshaller:marshal(Message, Options).

encoding_rules_test() ->
	Options = [{field_marshaller, ?MODULE}, {mti_marshaller, ?MODULE}],
	Message0 = erl8583_message:set(0, "1100", erl8583_message:new()),
	Message1 = erl8583_message:set(1, "V1", Message0),
	<<"11001993">> = erl8583_marshaller:marshal(Message1, Options).

unmarshal_no_encoders_test() ->
	Message = erl8583_marshaller:unmarshal(<<>>, []),
	[] = erl8583_message:get_fields(Message).

unmarshal_mti_test() ->
	Message = erl8583_marshaller:unmarshal(<<0, 2, 0, 0>>, [{mti_marshaller, ?MODULE}]),
	[0] = erl8583_message:get_fields(Message).

unmarshal_bitmap_test() ->
	Message = erl8583_marshaller:unmarshal(<<0, 2, 0, 0, 7, 1, 2, 3>>, [{mti_marshaller, ?MODULE}, {field_marshaller, ?MODULE}, {bitmap_marshaller, ?MODULE}]),
	[0, 1, 2, 3] = erl8583_message:get_fields(Message),
	<<"1">> = erl8583_message:get(1, Message).
	
unmarshal_init_test() ->
	Message = erl8583_marshaller:unmarshal(<<$S, 0, 2, 0, 0, 31, 1, 2, 3, 4, 5, $E>>, [{field_marshaller, ?MODULE},
																			  {mti_marshaller, ?MODULE}, 
																			  {bitmap_marshaller, ?MODULE},
																			  {init_marshaller, ?MODULE}]),
	[0, 1, 2, 3, 4, 5] = erl8583_message:get_fields(Message),
	<<"0200">> = erl8583_message:get(0, Message),
	<<"4">> = erl8583_message:get(4, Message).

unmarshal_additional_fields_test() ->
	Message = erl8583_marshaller:unmarshal(<<0, 2, 0, 0, 30, 10, 20, 30>>, [{mti_marshaller, ?MODULE}, {field_marshaller, ?MODULE}, {bitmap_marshaller, ?MODULE}]),
	[0, 10, 20, 30] = erl8583_message:get_fields(Message),
	<<10>> = erl8583_message:get(10, Message),
	<<20>> = erl8583_message:get(20, Message),
	<<30>> = erl8583_message:get(30, Message).

marshal_init_test() ->
	Message0 = erl8583_message:set(0, "0100", erl8583_message:new()),
	Message1 = erl8583_message:set(1, "V1", Message0),
	Message2 = erl8583_message:set(2, "V2", Message1),	
	Message3 = erl8583_message:set(3, "V3", Message2),
	<<"X0110V1V2V3">> = erl8583_marshaller:marshal(Message3, [{init_marshaller, ?MODULE}, {field_marshaller, ?MODULE}, {mti_marshaller, ?MODULE}]).

unmarshal_end_test() ->
	Message = erl8583_marshaller:unmarshal(<<$S, 0, 2, 0, 0, 31, 1, 2, 3, 4, 5, $E>>, [{field_marshaller, ?MODULE},
																			  {mti_marshaller, ?MODULE}, 
																			  {bitmap_marshaller, ?MODULE},
																			  {init_marshaller, ?MODULE},
																			  {end_marshaller, ?MODULE}]),
	[0, 2, 3, 4, 5] = erl8583_message:get_fields(Message),
	<<"0200">> = erl8583_message:get(0, Message),
	<<"4">> = erl8583_message:get(4, Message).
	
marshal_field_arranger_test() ->
	Message0 = erl8583_message:set(0, "0100", erl8583_message:new()),
	Message1 = erl8583_message:set(1, "V1", Message0),
	Message2 = erl8583_message:set(2, "V2", Message1),	
	Message3 = erl8583_message:set(3, "V3", Message2),
	<<"0100V2V1V3">> = erl8583_marshaller:marshal(Message3, [{field_arranger, ?MODULE}, {field_marshaller, ?MODULE}, {mti_marshaller, ?MODULE}]).

unmarshal_field_arranger_test() ->
	Message = erl8583_marshaller:unmarshal(<<0, 2, 0, 0, 30, 20, 10, 30>>, [{field_arranger, ?MODULE}, {mti_marshaller, ?MODULE}, {field_marshaller, ?MODULE}, {bitmap_marshaller, ?MODULE}]),
	[0, 10, 20, 30] = erl8583_message:get_fields(Message),
	<<10>> = erl8583_message:get(10, Message),
	<<20>> = erl8583_message:get(20, Message),
	<<30>> = erl8583_message:get(30, Message).


%%
%% Local Functions
%%

