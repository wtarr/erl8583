-module(erl8583_macro_map).
-compile(export_all).

-include("erl8583_field_ids.hrl").

%% for use in elixir projects

card_acceptor_name_location() ->
	?CARD_ACCEPTOR_NAME_LOCATION.

message_authentication_code() ->
	?MESSAGE_AUTHENTICATION_CODE.