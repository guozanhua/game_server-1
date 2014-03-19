%%% The MIT License (MIT)
%%%
%%% Copyright (c) 2014-2024
%%% Savin Max <mafei.198@gmail.com>
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%%
%%% @doc
%%%        Check a list of functions and return when there is a error,
%%%        or reach the end.
%%% @end
%%% Created :  三  3 19 15:09:27 2014 by Savin Max

-module(filter_chain).
-export([transmit/2, indie/1]).

transmit([Fun], Args) ->
    Fun(Args);
transmit([Fun|T], Args) ->
    case Fun(Args) of
        {ok, NewArgs} -> transmit(T, NewArgs);
        {fail, Reason} -> {fail, Reason}
    end.

indie([{Fun, Args}]) ->
    Fun(Args);
indie([{Fun, Args}|T]) ->
    case Fun(Args) of
        ok -> indie(T);
        {fail, Reason} -> {fail, Reason}
    end.
