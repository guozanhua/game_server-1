-module (utils_protocol).
-export ([encode/1,
          decode/2,
          encode_integer/1,
          decode_integer/1,
          encode_float/1,
          decode_float/1,
          encode_tuple/1,
          decode_tuple/2,
          encode_list/1,
          decode_list/2,
          encode_string/1,
          decode_string/1]).

%%Protocol
-define (INTEGER, 32).
-define (FLOAT,   32).
-define (STRING,  16).
-define (ARRAY,   16).
-define (REQUEST_TYPE, 8).

%%整数
encode_integer(Integer) when is_integer(Integer) ->
    <<Integer:?INTEGER>>.
decode_integer(<<Integer:?INTEGER, Data/binary>>) ->
    {Integer, Data}.

%%浮点数
encode_float(Float) when is_float(Float) ->
    <<Float:?FLOAT/float>>.
decode_float(<<Float:?FLOAT/float, Data/binary>>) ->
    {Float, Data}.

%%字符串
encode_string(String) when is_binary(String) ->
    Length = byte_size(String),
    list_to_binary([<<Length:?STRING>>, String]).
decode_string(<<Length:?STRING/unsigned-big-integer, Data/binary>>) ->
    {StringData, StringLeftData} = split_binary(Data, Length),
    {StringData, StringLeftData}.

%% 编码元组
encode_tuple(Tuple) when is_tuple(Tuple) ->
    DataList = [encode(Item) || Item <- tuple_to_list(Tuple)],
    list_to_binary(DataList).

%% 解码元组    
%% 例子: {1, 1.0, <<"hello">>, ...}  解码规则: {integer, float, string, ...}
%% 例子: {1, 1.0, <<"hello">>, [{1, 1.0, <<"world">>, ...}, ...]}  解码规则: {integer, float, string, [{integer, float, string, ...}], ...}
decode_tuple(<<Data/binary>>, DecodeRule) ->
    DecodedList = decode(Data, tuple_to_list(DecodeRule)),
    TupleSize = tuple_size(DecodeRule), 
    {Array, [DataLeft]} = lists:split(TupleSize, DecodedList),
    {list_to_tuple(Array), DataLeft}.

%% 编码列表
encode_list(List) when is_list(List) ->
    Len = length(List),
    DataList = [encode(Item) || Item <- List],
    list_to_binary([<<Len:?ARRAY/integer>>, DataList]).

%% 解码列表
%% 规则: 只能解码规则数组，即数组内每个元素的类型和结构必须一样
%% =====================基础解码例子==========================
%% 例子: [1, 2, 3, ...]  解码规则: [integer]
%% 例子: [1.0, 2.0, 3.0, ...]  解码规则: [float]
%% 例子: [<<"a">>, <<"b">>, <<"c">>, ...]  解码规则: [string]
%% 例子: [{1, 2.0, <<"hello">>, ...}, {2, 3.0, <<"world">>, ...}, ...]  解码规则: [{integer, float, string, ...}]
%% =====================嵌套解码例子==========================
%% 例子: [[1, 2, 3, ...], ...]  解码规则: [[integer]] 
%% 例子: [[1.0, 2.0, 3.0, ...], ...]  解码规则: [[float]] 
%% 例子: [[<<"a">>, <<"b">>, <<"c">>, ...], ...]  解码规则: [[string]] 
%% 例子: [[{1, 2.0, <<"hello">>, ...}, {2, 3.0, <<"world">>, ...}, ...], ...]  解码规则: [[{integer, float, string, ...}]] 
%% 例子: ...
decode_list(<<ListLen:?ARRAY, Data/binary>>, [RepeatElement | _]) ->
    TypeList = lists:duplicate(ListLen, RepeatElement),
    DecodedList = decode(Data, TypeList),
    {Array, [DataLeft]} = lists:split(ListLen, DecodedList),
    {Array, DataLeft}.

%% =====数据类型映射======
%% Erlang        其他语言
%% Integer       Integer
%% Float         Float
%% Binary        String
%% Tuple         Hash
%% List          Array

%% Erlang数据类型编码
%% 字符串支持: 仅支持BinaryString, 不支持String
encode(Info) when is_integer(Info) ->
    encode_integer(Info);
encode(Info) when is_float(Info) ->
    encode_integer(Info);
encode(Info) when is_atom(Info) ->
    encode_string(atom_to_binary(Info, utf8));
%% 二进制字符串
encode(Info) when is_binary(Info) -> 
    encode_string(Info);
encode(Info) when is_tuple(Info) ->
    encode_tuple(Info);
encode(Info) when is_list(Info) ->
    encode_list(Info).

%%数据解码
decode(<<Data/binary>>, DecodeRuleList) when is_tuple(DecodeRuleList) ->
  DecodedList = decode(Data, tuple_to_list(DecodeRuleList)),
  list_to_tuple(lists:delete(<<>>, DecodedList));
decode(<<>>, []) ->
    [<<>>];
decode(<<Data/binary>>, []) ->
    [Data];
decode(<<Data/binary>>, [DecodeRule | DecodeRuleList]) when DecodeRule == integer ->
    {Integer, DataLeft} = decode_integer(Data),
    [Integer | decode(DataLeft, DecodeRuleList)];
decode(<<Data/binary>>, [DecodeRule | DecodeRuleList]) when DecodeRule == float ->
    {Float, DataLeft} = decode_float(Data),
    [Float | decode(DataLeft, DecodeRuleList)];
decode(<<Data/binary>>, [DecodeRule | DecodeRuleList]) when DecodeRule == string ->
    {String, DataLeft} = decode_string(Data),
    [String | decode(DataLeft, DecodeRuleList)];
decode(<<Data/binary>>, [DecodeRule | DecodeRuleList]) when is_tuple(DecodeRule) ->
    {Array, DataLeft} = decode_tuple(Data, DecodeRule),
    [Array | decode(DataLeft, DecodeRuleList)];
decode(<<Data/binary>>, [DecodeRule | DecodeRuleList]) when is_list(DecodeRule) ->
    {Array, DataLeft} = decode_list(Data, DecodeRule),
    [Array | decode(DataLeft, DecodeRuleList)].