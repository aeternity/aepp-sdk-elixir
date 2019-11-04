defmodule AeppSDK.Middleware do
  @moduledoc """
  A wrapper module for Aeternity middleware API calls. Contains all HTTP requests, exposed by middleware.
  Where it is possible, optional parameters are also supported, like "limit" and "page".

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.
  """
  alias AeppMiddleware.Api.Default, as: Middleware
  alias AeppSDK.Client

  @doc """
  Gets currently active channels.

  ## Example
      iex()> AeppSDK.Middleware.get_active_channels(client)
      {:ok,
        ["ch_pXcot855823NqFB7NUCFpew8hkiCfyvAz7xi58SGnPGJaJr8H",
        "ch_Q6rUn61CviD9U2AiF3iQ7oxzqSAWXgpizQ3SzToDBMMXxiTaW",
        "ch_bV5AYukdpuXC9VGyh4gw84YA7uruM1HXMqQ7ibBQeZgqsvTtS",
        "ch_xymUJvByRJTDhXGjMj9oZXp8febkGEFUYi5cQsTc5H3SaLiiw",
        "ch_uQMHczzyehpuXotp3Z66fskfAYuvJX3sBcaNM6tdEF3PVyu7s", ...]
      }
  """
  @spec get_active_channels(Client.t()) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def get_active_channels(%Client{middleware: connection}) do
    Middleware.get_active_channels(connection)
  end

  @doc """
  Gets currently active name auctions.

  ## Example
      iex()> AeppSDK.Middleware.get_active_name_auctions(client)
      {:ok,
        [
          %{
            expiration: 163904,
            name: "valiotest123.chain",
            winning_bid: "2865700000000000000",
            winning_bidder: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9"
          },
          %{
            expiration: 171645,
            name: "gbunwe.chain",
            winning_bid: "53994045000000004096",
            winning_bidder: "ak_2UQWMtoZJd5vv5e7BrcXaG6DV52RjSHbH1SnzsDhhrqzFPLg3k"
          },
          %{
            expiration: 171645,
            name: "hvmuov.chain",
            winning_bid: "51422900000000000000",
            winning_bidder: "ak_2oTSYyd18L1y5qJ4L55jxoSM3KmdGwhuPCmaiGWxiihM4i2TWw"
          }, ...
        ]
      }
  """
  @spec get_active_name_auctions(Client.t(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_active_name_auctions(%Client{middleware: connection}, opts \\ []) do
    Middleware.get_active_name_auctions(connection, opts)
  end

  @doc """
  Gets the count of  currently active name auctions.

  ## Example
      iex()> AeppSDK.Middleware.get_active_name_auctions_count(client)
      {:ok, %{count: 21, result: "OK"}}
  """
  @spec get_active_name_auctions_count(Client.t(), list()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_active_name_auctions_count(%Client{middleware: connection}, opts \\ []) do
    Middleware.get_active_name_auctions_count(connection, opts)
  end

  @doc """
  Gets active names.

  ## Example
      iex()> AeppSDK.Middleware.get_active_names(client, limit: 3, page: 1)
      {:ok,
        [
          %{
            auction_end_height: 162076,
            created_at_height: 162076,
            expires_at: 212123,
            name: "hhhhjjjjjkkkkklllll2.chain",
            name_hash: "nm_Q4KxpLCRNULjfHbbW4dcJLbAAddjBgwapUS9gccy2K2Cm9eJV",
            owner: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
            pointers: [
              %{
                id: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
                key: "account_pubkey"
              }
            ],
            tx_hash: "th_25d9WdqBWBudBLPiRqitXR5mrKt9PSxhqpGFNys6a2etwcHnXz"
          },
          %{
            auction_end_height: 162553,
            created_at_height: 162073,
            expires_at: 212553,
            name: "november1.chain",
            name_hash: "nm_2oVYPHRg9XVei3H8UqWQ3NTLuzHN2Tz2tZ2STKbD8nVgMWfe6D",
            owner: "ak_2swhLkgBPeeADxVTAVCJnZLY5NZtCFiM93JxsEaMuC59euuFRQ",
            pointers: nil,
            tx_hash: "th_25V7KuVypp7twWgiavBebeXvb6pe46RaWV48b6nPJefNZLsCFi"
          },
          %{
            auction_end_height: 161982,
            created_at_height: 161982,
            expires_at: 211982,
            name: "testingnamechain.chain",
            name_hash: "nm_21Lx9u3PFirqrvdSTMRkRD8WVZm7RBAo36vWBMiwQ6a9SBKL1g",
            owner: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9",
            pointers: nil,
            tx_hash: "th_28ZaX6BzqKoBDdtJNjaggNtpbAbMKTnK5J8XSoprPzNmP6Xv5p"
          }
        ]}
  """
  @spec get_active_names(Client.t(), list()) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def get_active_names(%Client{middleware: connection}, opts \\ []) do
    Middleware.get_active_names(connection, opts)
  end

  @doc """
  Gets all contracts.

  ## Example
      iex()> AeppSDK.Middleware.get_all_contracts(client)
      {:ok,
        [
          %{
            block_height: 163501,
            contract_id: "ct_2BLESai7Yn8nYH7GcvpW53unNqftPc5etX4PzK1LTxcXhuggZA",
            transaction_hash: "th_PW77BD2Bbu1cgQX9PZGkEdkKqgn5DGC17r63GYhbTkta4EWXs"
          },
          %{
            block_height: 163495,
            contract_id: "ct_24y4LnJAX8s7ctdQ7e5ShqKVMeA176da5dTgkpJeLMTADPUgFL",
            transaction_hash: "th_2hrdRRct9g9cBMKd6ng8kar1ZCd4KLmYdqL8RW6FhkfMhyaoJ7"
          },
          %{
            block_height: 163495,
            contract_id: "ct_2ofvJh4ZpGLJdB25cGit41bC42vcKbC5vi8T9Js6EREe24RbfN",
            transaction_hash: "th_3tX9UJPzaeBMgQf4UziNXkHfCNaBb79YqUKjnv8Sv5r4TjE56"
          },
          %{...},
          ...
        ]
      }
  """
  @spec get_all_contracts(Client.t()) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def get_all_contracts(%Client{middleware: connection}) do
    Middleware.get_all_contracts(connection)
  end

  @doc """
  Gets all names.

  ## Example
      iex()> AeppSDK.Middleware.get_all_names(client, limit: 3, page: 1)
      {:ok,
        [
         %{
           auction_end_height: 163904,
           created_at_height: 163424,
           expires_at: 213904,
           name: "valiotest123.chain",
           name_hash: "nm_26BZCRgqZt7fBscTvwpTb8Ur6tEaN6wCjHzvjsf5dKtjS4RYEk",
           owner: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9",
           pointers: nil,
           tx_hash: "th_2SSzgLbmrA6jiJqTbEc87daMSJ7HpJ2tccpKG2KPrqbNaJ4b2E"
         },
         %{
           auction_end_height: 162076,
           created_at_height: 162076,
           expires_at: 212123,
           name: "hhhhjjjjjkkkkklllll2.chain",
           name_hash: "nm_Q4KxpLCRNULjfHbbW4dcJLbAAddjBgwapUS9gccy2K2Cm9eJV",
           owner: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
           pointers: [
             %{
               id: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
               key: "account_pubkey"
             }
           ],
           tx_hash: "th_25d9WdqBWBudBLPiRqitXR5mrKt9PSxhqpGFNys6a2etwcHnXz"
         },
         %{
           auction_end_height: 162553,
           created_at_height: 162073,
           expires_at: 212553,
           name: "november1.chain",
           name_hash: "nm_2oVYPHRg9XVei3H8UqWQ3NTLuzHN2Tz2tZ2STKbD8nVgMWfe6D",
           owner: "ak_2swhLkgBPeeADxVTAVCJnZLY5NZtCFiM93JxsEaMuC59euuFRQ",
           pointers: nil,
           tx_hash: "th_25V7KuVypp7twWgiavBebeXvb6pe46RaWV48b6nPJefNZLsCFi"
         }
        ]}
  """
  @spec get_all_names(Client.t(), list()) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def get_all_names(%Client{middleware: connection}, opts \\ []) do
    Middleware.get_all_names(connection, opts)
  end

  @doc """
  Gets all currently active oracles.

  ## Example
      iex()> AeppSDK.Middleware.get_all_oracles(client, limit: 3, page: 1)
      {:ok,
        [
          %{
            block_height: 157646,
            expires_at: 158146,
            oracle_id: "ok_2EaKARLitjLUsYxvL8tFhhUD3Z9EiBieD6yBAaGztJNcjKogXU",
            transaction_hash: "th_AxLuDsKRsjmpRXcCp17wMiVumSkR7pH9XhKhRgXRDSiC438cx",
            tx: %{
              abi_version: 0,
              account_id: "ak_2EaKARLitjLUsYxvL8tFhhUD3Z9EiBieD6yBAaGztJNcjKogXU",
              fee: 16792000000000,
              nonce: 75,
              oracle_ttl: %{type: "delta", value: 500},
              query_fee: 1,
              query_format: "{'domain': str}",
              response_format: "{'txt': str}",
              ttl: 158146,
              type: "OracleRegisterTx",
              version: 1
            }
          },
          %{
            block_height: 155341,
            expires_at: 155841,
            oracle_id: "ok_MtAkGssVvAQWXuvyGSiys1t29BiYmD1FoFswk7kxH5obNhtpg",
            transaction_hash: "th_c2YYRtk5PLe1jrTg7BKvFjcMHor8vqP9ziD17hirXWKAdGr3h",
            tx: %{
              abi_version: 0,
              account_id: "ak_MtAkGssVvAQWXuvyGSiys1t29BiYmD1FoFswk7kxH5obNhtpg",
              fee: 16472000000000,
              nonce: 50,
              oracle_ttl: %{type: "delta", value: 500},
              query_fee: 30000,
              query_format: "string",
              response_format: "string",
              type: "OracleRegisterTx",
              version: 1
            }
          },
          %{
            block_height: 154814,
            expires_at: 155314,
            oracle_id: "ok_2EaKARLitjLUsYxvL8tFhhUD3Z9EiBieD6yBAaGztJNcjKogXU",
            transaction_hash: "th_UrvmhhvW8y7ovaXSwwupm64FBxySV32QZTBdP4ZoMRRxzXz8M",
            tx: %{
              abi_version: 0,
              account_id: "ak_2EaKARLitjLUsYxvL8tFhhUD3Z9EiBieD6yBAaGztJNcjKogXU",
              fee: 16792000000000,
              nonce: 65,
              oracle_ttl: %{type: "delta", value: 500},
              query_fee: 1,
              query_format: "{'domain': str}",
              response_format: "{'txt': str}",
              ttl: 154864,
              type: "OracleRegisterTx",
              version: 1
            }
          }
      ]}
  """
  @spec get_all_oracles(Client.t(), list) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def get_all_oracles(%Client{middleware: connection}, opts \\ []) do
    Middleware.get_all_oracles(connection, opts)
  end

  @doc """
  Gets current chain size.

  ## Example
      iex()> AeppSDK.Middleware.get_chain_size(client)
      {:ok, %{size: 2231715109}}
  """
  @spec get_chain_size(Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_chain_size(%Client{middleware: connection}) do
    Middleware.get_chain_size(connection)
  end

  @doc """
  Gets channel transactions by channel id.

  ## Example
      iex()> AeppSDK.Middleware.get_channel_txs(client, "ch_JP22NWe19jPauZ67yNANC233oCgMnXpJ8JFMvRa29nnU4KSEb")
      {:ok,
        %{
         transactions: [
           %{
             block_hash: "mh_2tV4ynneNVoNhUUk7n7QdFSUUYMHAF51bYM9eqN6pR4jzfiooq",
             block_height: 78305,
             hash: "th_2a4mKk47yzeoWRsCtZfWWgBnw874crjym1uEsJLbYer9iuPddJ",
             signatures: ["sg_8ymgDq6ggivjL9NqNitSrSQE1o4ng8GhFydrR9MME7C38HEtA9j7dU3ejTVNWE8fMAxJg3C51uNta97YuzKHJHLaoxmdw",
              "sg_U7oPAhQBtf4FRLE3TC5a1aFPvXrrGEvLccTeJVSrnho86Yfa6Ab5tTG5CrRtt9oFYu52XTfX33SEGb1sBb3Asa9QC6HWM"],
             tx: %{
               channel_reserve: 20000000000,
               delegate_ids: [],
               fee: 20000000000000,
               initiator_amount: 1000000000000000,
               initiator_id: "ak_2mwRmUeYmfuW93ti9HMSUJzCk1EYcQEfikVSzgo6k2VghsWhgU",
               lock_period: 1,
               nonce: 546,
               responder_amount: 1000000000000000,
               responder_id: "ak_fUq2NesPXcYZ1CcqBcGC3StpdnQw3iVxMA3YSeCNAwfN4myQk",
               state_hash: "st_gLqNE4i3IL/+x60HN/5dlp7wgSLZWDJvSspVomecw/IsNYVA",
               type: "ChannelCreateTx",
               version: 1
             }
           }
         ]
      }}
  """
  @spec get_channel_txs(AeppSDK.Client.t(), String.t()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_channel_txs(%Client{middleware: connection}, <<"ch_", _::binary>> = channel_id) do
    Middleware.get_channel_tx(connection, channel_id)
  end

  @doc """
  Gets currently available middleware compiler's version.

  ## Example
      iex()> AeppSDK.Middleware.get_compilers(client)
      {:ok, %{compilers: ["4.0.0"]}}
  """
  @spec get_compilers(Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_compilers(%Client{middleware: connection}) do
    Middleware.get_compilers(connection)
  end

  @doc """
  Gets contracts calls by contract id.

  ## Example
      iex> AeppSDK.Middleware.get_contract_address_calls(client, "ct_2ofvJh4ZpGLJdB25cGit41bC42vcKbC5vi8T9Js6EREe24RbfN")
      {:ok, []}
  """
  @spec get_contract_address_calls(Client.t(), String.t()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_contract_address_calls(
        %Client{middleware: connection},
        <<"ct_", _::binary>> = contract_id
      ) do
    Middleware.get_contract_address_calls(connection, contract_id)
  end

  @doc """
  Gets contract tx information.

  ## Example
      iex()> AeppSDK.Middleware.get_contract_tx(client, "ct_2ofvJh4ZpGLJdB25cGit41bC42vcKbC5vi8T9Js6EREe24RbfN")
      {:ok,
        %{
         transactions: [
           %{
             block_hash: "mh_P3unBGPipoRi5gPsAjQd5YaVD3XA51LPYhdcQz5yptnXwJgSD",
             block_height: 163495,
             hash: "th_3tX9UJPzaeBMgQf4UziNXkHfCNaBb79YqUKjnv8Sv5r4TjE56",
             signatures: ["sg_9iYLKihjXgqUUqkiYgHYcJHvKSwoPUBLM99rekf2XBfbuUNQkqUgpKvMG5BRMSANVv6BWZPK5BeiozBbHPkKCPTSLbZHH"],
             tx: %{
               abi_version: 3,
               amount: 0,
               call_data: "cb_KxFE1kQfP4oEp9E=",
               code: "cb_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",
               deposit: 0,
               fee: 107360000000000,
               gas: 1579000,
               gas_price: 1000000000,
               nonce: 4,
               owner_id: "ak_vrCNKooX2M5czsTvDyuLctZ5BRpfLYzVjHrD4wZoat5LJTGTt",
               type: "ContractCreateTx",
               version: 1,
               vm_version: 5
             }
           }
         ]
      }}
  """
  @spec get_contract_tx(Client.t(), String.t()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_contract_tx(%Client{middleware: connection}, <<"ct_", _::binary>> = contract_id) do
    Middleware.get_contract_tx(connection, contract_id)
  end

  @doc """
  Gets current transactions count.

  ## Example
      iex()> AeppSDK.Middleware.get_current_tx_count(client)
      {:ok, %{count: 3563570}}
  """
  @spec get_current_tx_count(Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_current_tx_count(%Client{middleware: connection}) do
    Middleware.get_current_tx_count(connection)
  end

  @doc """
  Gets generations by provided range.

  ## Example
      iex()> from = 1
      iex()> to = 3
      iex()> AeppSDK.Middleware.get_generations_by_range(client, from, to)
      {:ok,
        %{
         data: %{
           "1": %{
             beneficiary: "ak_tjnw1KcmnwfqXvhtGa9GRjanbHM3t6PmEWEWtNMM3ouvNKRu5",
             hash: "kh_23YYKqpKsL5zk58jWrBJaX72NuSh6x46AMLKFXvCgPJpqoYLhq",
             height: 1,
             micro_blocks: %{},
             miner: "ak_zhweEwzmZUdFFDFSaYNp7VijDkykTLQEzLeEqwUwyoZyApjdK",
             nonce: "15040253459488731327",
             pow: "[19301801, 28095945, 30242271, 41791129, 82345881, 91723980, 102883439, 104069957, 106940641, 120282690, 142003713, 143957273, 169264489, 173803306, 174682886, 195785945, 207612483, 217325518, 249938129, 251061536, 303550072, 304164231, 312469475, 312651779, 315101105, 324375018, 338690907, 351855961, 386966019, 402286237, 421227072, 429874165, 443260413, 443282006, 448769329, 453954186, 458940673, 462872156, 476035233, 518931704, 522144527, 524414597]",
             prev_hash: "kh_wUCideEB8aDtUaiHCtKcfywU6oHZW6gnyci8Mw6S1RSTCnCRu",
             prev_key_hash: "kh_wUCideEB8aDtUaiHCtKcfywU6oHZW6gnyci8Mw6S1RSTCnCRu",
             state_hash: "bs_2aBz1QS23piMnSmZGwQk8iNCHLBdHSycPBbA5SHuScuYfHATit",
             target: 553713663,
             time: 1543365752204,
             version: 1
           },
           "2": %{
             beneficiary: "ak_tjnw1KcmnwfqXvhtGa9GRjanbHM3t6PmEWEWtNMM3ouvNKRu5",
             hash: "kh_iLwwTNfbTqbQ7V2YLQ7gDMBLjSWDMbxVEWGjZmhyChdXYQwSu",
             height: 2,
             micro_blocks: %{},
             miner: "ak_KtomXcxCxYKzsWEkg7PBjRkJnDbm6spCst9xu3YxW7LJVKsS3",
             nonce: "6403914643639874925",
             pow: "[9984723, 18650504, 31167967, 31826588, 44902620, 56808905, 57785192, 84575784, 86542607, 101408783, 104898904, 116623406, 129971517, 130064166, 133694218, 140897051, 144025750, 151252661, 155243552, 166095989, 223475660, 257256157, 264618551, 268964880, 297680261, 325751712, 328577779, 337697626, 351593578, 388391126, 403553279, 428485724, 433882115, 454241604, 458860106, 459810672, 485373033, 487640676, 494206006, 505861883, 514721839, 527221220]",
             prev_hash: "kh_23YYKqpKsL5zk58jWrBJaX72NuSh6x46AMLKFXvCgPJpqoYLhq",
             prev_key_hash: "kh_23YYKqpKsL5zk58jWrBJaX72NuSh6x46AMLKFXvCgPJpqoYLhq",
             state_hash: "bs_2aBz1QS23piMnSmZGwQk8iNCHLBdHSycPBbA5SHuScuYfHATit",
             target: 553713663,
             time: 1543366085754,
             version: 1
           },
           "3": %{
             beneficiary: "ak_tjnw1KcmnwfqXvhtGa9GRjanbHM3t6PmEWEWtNMM3ouvNKRu5",
             hash: "kh_224cbECuLXGgtvpztWLk4Gzt5rmbZPct44ZRp8D53pDnMTUZbL",
             height: 3,
             micro_blocks: %{},
             miner: "ak_tWQsH4xDw9BQTskEhxfzTo1YKKvHPv8HQuGwznE2deVYnB56M",
             nonce: "9125645628778770359",
             pow: "[5405614, 23679211, 25026305, 31199047, 34932131, 44406298, 44495059, 45425472, 54549729, 68929916, 86198221, 122096165, 147175413, 149290166, 150539341, 176858670, 182595876, 195787048, 195908320, 258102447, 283305487, 302006333, 313896693, 323002385, 329065752, 348066385, 356436712, 364424972, 365325129, 377790606, 430401010, 456999253, 469423279, 474209533, 475109438, 477756370, 487904326, 498235474, 500574450, 514064550, 534556511, 535480510]",
             prev_hash: "kh_iLwwTNfbTqbQ7V2YLQ7gDMBLjSWDMbxVEWGjZmhyChdXYQwSu",
             prev_key_hash: "kh_iLwwTNfbTqbQ7V2YLQ7gDMBLjSWDMbxVEWGjZmhyChdXYQwSu",
             state_hash: "bs_2aBz1QS23piMnSmZGwQk8iNCHLBdHSycPBbA5SHuScuYfHATit",
             target: 553713663,
             time: 1543367260908,
             version: 1
           }
         },
         total_micro_blocks: 0,
         total_transactions: 0
      }}
  """
  @spec get_generations_by_range(Client.t(), integer, integer, list()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_generations_by_range(%Client{middleware: connection}, from, to, opts \\ [])
      when is_integer(from) and is_integer(to) do
    Middleware.get_generations_by_range(connection, from, to, opts)
  end

  @doc """
  Gets height by provided timestamp in milliseconds.

  ## Example
      iex()> AeppSDK.Middleware.get_height_by_time(client, 1_572_883_000_000)
      {:ok, %{height: 163532}}
  """
  @spec get_height_by_time(AeppSDK.Client.t(), integer) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_height_by_time(%Client{middleware: connection}, milliseconds)
      when is_integer(milliseconds) do
    Middleware.get_height_by_time(connection, milliseconds)
  end

  @doc """
  Gets current middleware status.

  ## Example
      iex()> AeppSDK.Middleware.get_middleware_status(client)
      {:ok,
        %{OK: true, queue_length: 0, seconds_since_last_block: 178, version: "0.10.0"}}
  """
  @spec get_middleware_status(AeppSDK.Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_middleware_status(%Client{middleware: connection}) do
    Middleware.get_mdw_status(connection)
  end

  @doc """
  Gets name auction bids by address.

  ## Example
      iex(65)> AeppSDK.Middleware.get_name_auctions_bids_by_address(client, "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9")
      {:ok,
       [
         %{
           name_auction_entry: %{
             expiration: 163904,
             name: "valiotest123.chain",
             winning_bid: "2865700000000000000",
             winning_bidder: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9"
           },
           transaction: %{
             block_hash: "mh_2bnZzsXhBd7kofrMGKoR89S1Vo8uwnfRgjrgoLpMrSWSZRdCmU",
             block_height: 163424,
             fee: "180040000000000",
             hash: "th_2SSzgLbmrA6jiJqTbEc87daMSJ7HpJ2tccpKG2KPrqbNaJ4b2E",
             signatures: "sg_5GnuNxNS5BpbTU4eMajSxHuQt3b3K6JHnH219a6uR77iGY7TQKBYYvyuSKJpVZNa43S3AZNPkMFCpFXWvjMmyrCBQaRpx",
             size: 223,
             tx: %{
               account_id: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9",
               fee: 180040000000000,
               name: "valiotest123.chain",
               name_fee: 2865700000000000000,
               name_salt: 8914081986392545,
               nonce: 30,
               type: "NameClaimTx",
               version: 2
             },
             tx_type: "NameClaimTx"
           }
         },
         %{
           name_auction_entry: %{
             expiration: 161982,
             name: "testingnamechain.chain",
             winning_bid: "2865700000000000000",
             winning_bidder: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9"
           },
           transaction: %{
             block_hash: "mh_2bvndPYbjumABQZRsAxQ8EAkqtb9uuyk5sWQe3ncWCSqyTiHhu",
             block_height: 161982,
             fee: "165600000000000",
             hash: "th_28ZaX6BzqKoBDdtJNjaggNtpbAbMKTnK5J8XSoprPzNmP6Xv5p",
             signatures: "sg_JXk9Je3bWsuD989fWjnJgSMdRZBAXLSTrEzZRGyDMxmEsChMHq4vjLDfyZAGpw4oJMXwJ9qKcy4d3i43dQ7voQ93P6z4w",
             size: 226,
             tx: %{
               account_id: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9",
               fee: 165600000000000,
               name: "testingnamechain.chain",
               name_fee: 2865700000000000000,
               name_salt: 8285267173752605,
               nonce: 5,
               type: "NameClaimTx",
               version: 2
             },
             tx_type: "NameClaimTx"
           }
         }
       ]}
  """
  @spec get_name_auctions_bids_by_address(Client.t(), String.t(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_name_auctions_bids_by_address(%Client{middleware: connection}, account, opts \\ [])
      when is_binary(account) do
    Middleware.get_name_auctions_bidsby_address(connection, account, opts)
  end

  @doc """
  Gets name auction bids by name.

  ## Example
      iex()> AeppSDK.Middleware.get_name_auctions_bids_by_name(client, "valiotest123.chain")
      {:ok,
        [
          %{
            block_hash: "mh_2bnZzsXhBd7kofrMGKoR89S1Vo8uwnfRgjrgoLpMrSWSZRdCmU",
            block_height: 163424,
            fee: "180040000000000",
            hash: "th_2SSzgLbmrA6jiJqTbEc87daMSJ7HpJ2tccpKG2KPrqbNaJ4b2E",
            signatures: "sg_5GnuNxNS5BpbTU4eMajSxHuQt3b3K6JHnH219a6uR77iGY7TQKBYYvyuSKJpVZNa43S3AZNPkMFCpFXWvjMmyrCBQaRpx",
            size: 223,
            tx: %{
              account_id: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9",
              fee: 180040000000000,
              name: "valiotest123.chain",
              name_fee: 2865700000000000000,
              name_salt: 8914081986392545,
              nonce: 30,
              type: "NameClaimTx",
              version: 2
            },
            tx_type: "NameClaimTx"
          }
      ]}
  """
  @spec get_name_auctions_bids_by_name(Client.t(), String.t(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_name_auctions_bids_by_name(%Client{middleware: connection}, name, opts \\ [])
      when is_binary(name) do
    Middleware.get_name_auctions_bidsby_name(connection, name, opts)
  end

  @doc """
  Gets name information by account address.

  ## Example
      iex()> AeppSDK.Middleware.get_name_by_address(client, "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc")
      {:ok,
        [
         %{
           auction_end_height: 121384,
           created_at_height: 106504,
           expires_at: 171384,
           name: "aeternity.test",
           name_hash: "nm_2QvSFGwCHcEqMFrY3VAnTNxmDELnf69bEwQ6jDrHp8t7YDREYD",
           owner: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
           pointers: [
             %{
               id: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
               key: "account_pubkey"
             }
           ],
           tx_hash: "th_2sYEagAWZzagV3VWH2u11F3Wx4PZZ9Mh7YTV75JNmK2zSJLGws"
         },
         %{
           auction_end_height: 118155,
           created_at_height: 103275,
           expires_at: 168155,
           name: "davidyuk.test",
           name_hash: "nm_EstGDe5sJVEaWSYnKtbEATp1X9kbhbjX8hLEvUgMM7XSkndmh",
           owner: "ak_2swhLkgBPeeADxVTAVCJnZLY5NZtCFiM93JxsEaMuC59euuFRQ",
           pointers: [
             %{
               id: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
               key: "account_pubkey"
             }
           ],
           tx_hash: "th_jA3SPtRcf8SXWLwb9Tp2ccAjR6WJ3tsE4EyEMe7BiUxCgc33F"
         },
         %{
           auction_end_height: 162076,
           created_at_height: 162076,
           expires_at: 212123,
           name: "hhhhjjjjjkkkkklllll2.chain",
           name_hash: "nm_Q4KxpLCRNULjfHbbW4dcJLbAAddjBgwapUS9gccy2K2Cm9eJV",
           owner: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
           pointers: [
             %{
               id: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc",
               key: "account_pubkey"
             }
           ],
           tx_hash: "th_25d9WdqBWBudBLPiRqitXR5mrKt9PSxhqpGFNys6a2etwcHnXz"
         }
      ]}
  """
  @spec get_name_by_address(Client.t(), String.t(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_name_by_address(%Client{middleware: connection}, account, opts \\ [])
      when is_binary(account) do
    Middleware.get_name_by_address(connection, account, opts)
  end

  @doc """
  Gets oracle data by oracle id.

  ## Example
      iex> AeppSDK.Middleware.get_oracle_data(client, "ok_2hzMeKfxSTg3QBiin34PA1pzQwscULv3RcNuxMasaKzoUSH53o")
      {:ok,
        [
          %{
            query_id: "oq_bx4rA34C5yJPMFdYPnDWms7G2zBd5XfhRugcEJ5VMSMDfQ4Dg",
            request: %{
              fee: 17232000000000,
              hash: "th_x3ZprBPMBBFFEe3zTw3qoW7SHfg2qVss8gaiPHzyBubf3RpZ4",
              nonce: 2,
              oracle_id: "ok_2hzMeKfxSTg3QBiin34PA1pzQwscULv3RcNuxMasaKzoUSH53o",
              query: "Presidente de VZLA",
              query_fee: 30000,
              query_ttl: %{type: "delta", value: 10},
              response_ttl: %{type: "delta", value: 10},
              sender_id: "ak_2hzMeKfxSTg3QBiin34PA1pzQwscULv3RcNuxMasaKzoUSH53o",
              timestamp: 1567719861063,
              type: "OracleQueryTx",
              version: 1
            },
            response: %{
              fee: 17232000000000,
              hash: "th_2Pf8cFEzg5GBjmX7dPMLL19HMyF9b3kvAj4get8WT2iJ88euMv",
              nonce: 3,
              oracle_id: "ok_2hzMeKfxSTg3QBiin34PA1pzQwscULv3RcNuxMasaKzoUSH53o",
              query_id: "oq_bx4rA34C5yJPMFdYPnDWms7G2zBd5XfhRugcEJ5VMSMDfQ4Dg",
              response: "MADURO COño DE TU MADRE",
              response_ttl: %{type: "delta", value: 10},
              timestamp: 1567720145598,
              type: "OracleRespondTx",
              version: 1
            }
          }
      ]}
  """
  @spec get_oracle_data(Client.t(), String.t(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_oracle_data(
        %Client{middleware: connection},
        <<"ok_", _::binary>> = oracle_id,
        opts \\ []
      ) do
    Middleware.get_oracle_data(connection, oracle_id, opts)
  end

  @doc """
  Gets miner reward at given height.

  ## Example
      iex()> AeppSDK.Middleware.get_reward_at_height(client, 10_234)                                                   {:ok,
      {:ok,
        %{
         beneficiary: "ak_2iBPH7HUz3cSDVEUWiHg76MZJ6tZooVNBmmxcgVK6VV8KAE688",
         coinbase: "5831398157261209600",
         fees: "2400000",
         height: 10234,
         total: "5831398157263609600"
      }}
  """
  @spec get_reward_at_height(Client.t(), integer()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_reward_at_height(%Client{middleware: connection}, height) when is_integer(height) do
    Middleware.get_reward_at_height(connection, height)
  end

  @doc """
  Gets size of a blockchain at given height.

  ## Examples:
      iex()> AeppSDK.Middleware.get_size_at_height(client, 10_234)
      {:ok, %{size: 1220968}}
  """
  @spec get_size_at_height(Client.t(), integer()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_size_at_height(%Client{middleware: connection}, height) when is_integer(height) do
    Middleware.get_size_at_height(connection, height)
  end

  @doc """
  Get transactions made between 2 addresses.

  ## Example
      iex(80)> AeppSDK.Middleware.get_tx_between_address(client, client.keypair.public, client.keypair.public)
      {:ok,
        %{
          transactions: [
            %{
              block_hash: "mh_FVT3WxJPMeg1uFZDV7pXCrSekgCsoSmM3MztURDje3UCjGbyo",
              block_height: 162089,
              hash: "th_bd8qvyaTo45U7MKh1Y1PG7bCPmzqeiHWS1bTfK31kMZU1hZzZ",
              signatures: ["sg_DgGnuqnwHACmiKVv6uEk3a9H1g6EPshA6oSzoBFQ8wsBMRTCppLssLhivzk9JWGxTUqmFg2xzPDjV2dDGrqSwWGQoCYTP"],
              tx: %{
                amount: 10000,
                fee: 16700000000000,
                nonce: 8,
                payload: "ba_Xfbg4g==",
                recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
                sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
                type: "SpendTx",
                version: 1
              }
            },
            %{
              block_hash: "mh_imPyUPD9EyHqUa1nBRL1oi4JPjUEDAB9GRgGSXy4BWg7tQbgi",
              block_height: 162085,
              hash: "th_wG7ioeErrMFuKCX6o8iB5uijNuFbtn7EzrGzP4d3F6XvTCmR2",
              signatures: ["sg_Kv4YVVVWrgE2MS5Ejm4A7zZ4LDoncNMkJ4AKoyFNNbk9DG1xBZ4B7C3ihRs7HZaTazVj1A1rRXKrwMuqhuKKBV7gxo16B"],
              tx: %{
                amount: 10000,
                fee: 16700000000000,
                nonce: 7,
                payload: "ba_Xfbg4g==",
                recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
                sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
                type: "SpendTx",
                version: 1
              }
            },....]
      }}
  """
  @spec get_tx_between_address(Client.t(), binary(), binary()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_tx_between_address(%Client{middleware: connection}, sender, receiver)
      when is_binary(sender) and is_binary(receiver) do
    Middleware.get_tx_between_address(connection, sender, receiver)
  end

  @doc """
  Get transaction by given account

  ## Example
      iex> AeppSDK.Middleware.get_tx_by_account(client, client.keypair.public)
      {:ok,
        [
          %{
            block_hash: "mh_FVT3WxJPMeg1uFZDV7pXCrSekgCsoSmM3MztURDje3UCjGbyo",
            block_height: 162089,
            hash: "th_bd8qvyaTo45U7MKh1Y1PG7bCPmzqeiHWS1bTfK31kMZU1hZzZ",
            signatures: ["sg_DgGnuqnwHACmiKVv6uEk3a9H1g6EPshA6oSzoBFQ8wsBMRTCppLssLhivzk9JWGxTUqmFg2xzPDjV2dDGrqSwWGQoCYTP"],
            time: 1572621118801,
            tx: %{
              amount: 10000,
              fee: 16700000000000,
              nonce: 8,
              payload: "ba_Xfbg4g==",
              recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
              sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
              type: "SpendTx",
              version: 1
            }
          },
          %{
            block_hash: "mh_imPyUPD9EyHqUa1nBRL1oi4JPjUEDAB9GRgGSXy4BWg7tQbgi",
            block_height: 162085,
            hash: "th_wG7ioeErrMFuKCX6o8iB5uijNuFbtn7EzrGzP4d3F6XvTCmR2",
            signatures: ["sg_Kv4YVVVWrgE2MS5Ejm4A7zZ4LDoncNMkJ4AKoyFNNbk9DG1xBZ4B7C3ihRs7HZaTazVj1A1rRXKrwMuqhuKKBV7gxo16B"],
            time: 1572620262508,
            tx: %{
              amount: 10000,
              fee: 16700000000000,
              nonce: 7,
              payload: "ba_Xfbg4g==",
              recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
              sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
              type: "SpendTx",
              version: 1
            }
          }, ...
      ]}
  """
  @spec get_tx_by_account(Client.t(), binary, keyword) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_tx_by_account(%Client{middleware: connection}, account, opts \\ [])
      when is_binary(account) do
    Middleware.get_tx_by_account(connection, account, opts)
  end

  @doc """
  Gets all transactions in between the given generation range.

  ## Example
  #TODO tomorrow
  """
  @spec get_tx_by_generation_range(Client.t(), integer(), integer(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_tx_by_generation_range(%Client{middleware: connection}, from, to, opts \\ [])
      when is_integer(from) and is_integer(to) do
    Middleware.get_tx_between_address(connection, from, to, opts)
  end

  @doc """
  Gets transaction count by address.

  ## Example
      iex()> AeppSDK.Middleware.get_tx_count_by_address(client, client.keypair.public)
      {:ok, %{count: 9}}
  """
  @spec get_tx_count_by_address(Client.t(), binary, keyword) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_tx_count_by_address(%Client{middleware: connection}, address, opts \\ [])
      when is_binary(address) do
    Middleware.get_tx_count_by_address(connection, address, opts)
  end

  @doc """
  Gets transaction rate by provided date range.

  ## Example

  #TODO should be added tomorrow
  """
  @spec get_tx_rate_by_date_range(Client.t(), integer(), integer()) :: none
  def get_tx_rate_by_date_range(%Client{middleware: connection}, from, to)
      when is_integer(from) and is_integer(to) do
    Middleware.get_tx_rate_by_date_range(connection, from, to)
  end

  @doc """
  Searches for given name.

  ## Example
      iex()> AeppSDK.Middleware.search_name(client, "valiotest123.chain")
      {:ok,
        [
         %{
           auction_end_height: 163904,
           created_at_height: 163424,
           expires_at: 213904,
           name: "valiotest123.chain",
           name_hash: "nm_26BZCRgqZt7fBscTvwpTb8Ur6tEaN6wCjHzvjsf5dKtjS4RYEk",
           owner: "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9",
           pointers: nil,
           tx_hash: "th_2SSzgLbmrA6jiJqTbEc87daMSJ7HpJ2tccpKG2KPrqbNaJ4b2E"
         }
        ]}
  """
  @spec search_name(Client.t(), String.t()) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def search_name(%Client{middleware: connection}, name) when is_binary(name) do
    Middleware.search_name(connection, name)
  end

  @doc """
  Verify a contract by submitting the source, compiler version and contract identifier.

  ## Example
  #TODO Tomorrow  AeppSDK.Middleware.verify_contract client, body: %{contract_id: "ct_mBpDYtSPVANfymGUfo55fciHBrX7X9SvwWxVZqrKLtC1zapfW", source: source, compiler: "4.0.0"}
  """
  @spec verify_contract(Client.t(), list()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def verify_contract(%Client{middleware: connection}, opts \\ []) do
    Middleware.verify_contract(connection, opts)
  end
end
