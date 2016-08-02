%% -------------------------------------------------------------------
%%
%% Copyright (c) 2016 Basho Technologies, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(ts_simple_insert_iso8601).

-behavior(riak_test).

-include_lib("eunit/include/eunit.hrl").

-export([confirm/0]).

%% Epoch mappings for this test
-define(TESTS, [
                {"2016-08-02T10:00:00Z", 1470132000000},
                {"2016-08-02T10:00:00-05:30", 1470151800000},
                {"2016-08-02T24:00:00Z", 1470182400000},
                {"2016-08-02 23:59:59Z", 1470182399000},
                {"2016-08-03T23:59:60Z", 1470268800000},
                {"2016-08", 1470009600000},
                {"2016-08-04T15.5", 1470324600000},
                {"2016-08-02 05Z", 1470114000000}
               ]).

confirm() ->
    DDL = ts_util:get_ddl(),
    Table = ts_util:get_default_bucket(),
    {Cluster, Conn} = ts_util:cluster_and_connect(single),
    ts_util:create_and_activate_bucket_type(Cluster, DDL),

    QryFmt = "select * from GeoCheckin Where time >= ~B and time <= ~B and myfamily = 'family1' and myseries ='seriesX'",

    lists:foreach(
      fun({String, Epoch}) ->
              Qry = lists:flatten(
                      io_lib:format(QryFmt, [Epoch-10, Epoch+10])),

              {ok, {[], []}} = ts_util:single_query(Conn, Qry),

              ts_util:ts_insert_no_columns(Conn, Table,
                                           {<<"family1">>, <<"seriesX">>,
                                             unicode:characters_to_binary(String), <<"cloudy">>, 5.5}),
              {ok, {_Cols, OneRow}} = ts_util:single_query(Conn, Qry),
              ?assertEqual(1, length(OneRow))

      end, ?TESTS),
    pass.
