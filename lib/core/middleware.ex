defmodule AeppSDK.Middleware do
  @moduledoc """
  A wrapper module for AEternity middleware API calls. Contains all HTTP requests, exposed by middleware.
  Where it is possible, optional parameters are also supported, like "limit" and "page".

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.
  """
  alias AeppSDK.Client
  alias AeppMiddleware.Api.Default, as: Middleware

  @doc """
  Gets currently active channels

  Example:
  iex()> AeppSDK.Middleware.get_active_channels client
  {:ok,
  ["ch_pXcot855823NqFB7NUCFpew8hkiCfyvAz7xi58SGnPGJaJr8H",
  "ch_Q6rUn61CviD9U2AiF3iQ7oxzqSAWXgpizQ3SzToDBMMXxiTaW",
  "ch_bV5AYukdpuXC9VGyh4gw84YA7uruM1HXMqQ7ibBQeZgqsvTtS",
  "ch_xymUJvByRJTDhXGjMj9oZXp8febkGEFUYi5cQsTc5H3SaLiiw",
  "ch_uQMHczzyehpuXotp3Z66fskfAYuvJX3sBcaNM6tdEF3PVyu7s",
  "ch_2Vi1o8WurSvCxLrp4FJdhftJrMDDxC17LF93sFoGbs4BxXQCxR",
  "ch_214RAm1VhaqhevtsotLKz21RTTX9FJVwv4P2m8MM43MGnGRM5R",
  "ch_AASLHAYDA42gcCsVM1W7G29Ywi4xd4bZrMth536fXrMxFaCys",
  "ch_2HGk3yJmpU9vBvz922riaUEHbptek4P4WTcCqSirM8TjEWuqei",
  "ch_2e4zjaTrAa91ZJarNkHDHViu1aBAnjVTeBzqPLhzxSF6KPaut7",
  "ch_2BYjC8FEaC5x4o5Wi75gSPo3QPvtg5gx8jR1RDFqNNmPzGHHs8",
  "ch_2kuAW2daTvHGHPzh5qvUA43reCJf3NFRY9Bob76bSyputKi5x7",
  "ch_Gk6WBrRQL8sogFrYW8QCUhVJArUwPbKPYMbMdfrQPKqw6PPxB",
  "ch_gotk22zRvqDmKXanexqiA7E15gPVyvfEwaxPL4S5srfYeX8g1",
  "ch_2jgSXSmpB62dVDQgnqgzt5MCAq67CRm91pGWmQQKNSadKc73Wx",
  "ch_2hUwsQcbrSjGu6ywcHPY4GAkVDdSWDxPDtrLPJLxFARmTtPLG2",
  "ch_fw9PyowhGqLirDkKH5NZvVNKWhRkhfqW5Qk1QaUCWKHERvnyL",
  "ch_XNWUPk5QfT4CDy7uXU3DUNNDSuMZspDjkxUZQqyiS5LbYRQ58",
  "ch_HAcPmsPXT4FRWNzNQweH3Pk9qinTmc4QGgy1C4nL9vZm6gpNc",
  "ch_2hHtDUipMafeKCc2NPZxTNKsHvWkFqvkvZUJd6yhnHYfUSTLsL",
  "ch_aMMYtDGAKFg7zreqCVtXvtso92dBCBUsZ6pu1A3Zhv6JfHvwU",
  "ch_2R5ZoVRnWiXtfaeNoUXMVEqJpV2a9dyMyPVXzkR6dHeF3CwTRb",
  "ch_QVcBzKX4Ho6PccPSq7Vuau6C8rwBabFiB4BM6AzMRt716bJyy",
  "ch_6MGmW6CPizKJ555iEfK1X8kGKFi8ERMpAP1u2pcxVTsw2AY2G",
  "ch_283wxdyJAidtWqWHikvkPfNj89jrs88pxgtZwhFUEQFxoy1WSH",
  "ch_2kk5P99v2xwD6KPXwhNq6bZhnJRNm14WvNsGmBVUhsLxggDwDi",
  "ch_2Diky5Ub8UqjpEyUw5Vj77GXoyLRPstZuiPUTASrvfu7qSAjHL",
  "ch_D3kXM6HPQ2sisJytfxgCsfK3KndjV3cHyGjVYPfR4YW1se5d9",
  "ch_tWEwzLjSkm76nS33jGKiPL3Vf7CjauXhsi58d26BnkMa7fKCJ",
  "ch_2dtVxgsTYS7EzDT2a4FRuKtBZFUQAERBAwpokoMsC7D8AUN2Fx",
  "ch_2VZkwC2nAksiKAsGd51E9LGxGTaD3vesP1v1zVsBk8696oNdNH",
  "ch_2oURn636Msn6VaMvWuaufqutAy9kiV8Kcd79N7BK2FT9H2W82o",
  "ch_2eQYnupythn22jDTjnd32HhiezQ9y6WPg94Z2SsWoNhTUgmcob",
  "ch_9AcrRUiYpJU7cXVVd6ipcufaxNegKxwVRpF91WqssLGrQfzhF",
  "ch_QEiBhQ4poXLuczP226z4af9pnN5nPd8h3qDCrTYjSvRgVFx7k",
  "ch_2LJYMSmMQdQ3XewxTVuvXNVGaCd7dxxpSK6fFS9rhyRLmHUM9r",
  "ch_2PKUPw5qL3rYp8gPbwQbixcaryyMdH2wJpJT6HyNm5ZnH6abqw",
  "ch_2apzirEPfHCvRQhs7YethN4PUcGY2JTYjf11D4gewfYFZbPjQt",
  "ch_2AJzZHUQRVLr5utLwwEpvy81rA8VsxmoeXLYF4PU343toYqDaL",
  "ch_3N64FNAwGDMtECRbxeqw4WXQ64kcwD7wnqQJAGSHvcbCFtCkg",
  "ch_2cEq2dThV4B6JEn4iP4zU37m1dia5UjC9iam1ysecFUu2b5ArS",
  "ch_n8pJokm1siJVvJpRKQVk5rg4eS13YpgzYtNCJU2Y8FtmMuUc5",
  "ch_2FumwvxVpoopH5YxaT1QjfaY8PdvMvocSXCEuikX1M5kE3pGaA",
  "ch_KidWCBwBaV9kXzTnvua81AJzQ5s2V8Zciug1CbHp4z44bpRV3",
  "ch_2S1dXLx8SU1paFQiyevGH9jpkdBo7tZWVoiR1hSFyNbzpqYcf4",
  "ch_JP22NWe19jPauZ67yNANC233oCgMnXpJ8JFMvRa29nnU4KSEb",
  "ch_2iZp6rkDMePEqYFGcxJEgbA98Fvj7GDM7PKeW8pdbnNEcPyeRu",
  "ch_2rW7V9nHhjFxP3RNyeDNJ3HhTKQgfPED4xpkGMawLFLErqCgHw", ...]}
  """
  @spec get_active_channels(Client.t()) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def get_active_channels(%Client{middleware: connection}) do
    Middleware.get_active_channels(connection)
  end

  @doc """
    Gets currently active name auctions

    Example:
  iex()> AeppSDK.Middleware.get_active_name_auctions client
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
     },
     %{
       expiration: 171668,
       name: "etcbukr.chain",
       winning_bid: "36790595887500001280",
       winning_bidder: "ak_24W1Kqs9S2TyjXtsuXJk9osbK9aAeA9inwNpDdiD4eUsGZcrtp"
     },
     %{
       expiration: 171672,
       name: "dztphf.chain",
       winning_bid: "53994045000000004096",
       winning_bidder: "ak_kd8j3z2JbXTzKit7QJQJo6oBbkvruck7AMLHgDQy1d88JPHuZ"
     },
     %{
       expiration: 171687,
       name: "epdzd.chain",
       winning_bid: "91732410000000008192",
       winning_bidder: "ak_2uvumP74mjtC3N3JLpvmj5oWWjChEJnkfiLYRXg3CaPyJmJ5dQ"
     },
     %{
       expiration: 171690,
       name: "pyeqmjys.chain",
       winning_bid: "20623890000000000000",
       winning_bidder: "ak_rYp9opSQs674FFKU5a5EWyqBE4DiTUWiP3A8Nu3fNzcsbEfgn"
     },
     %{
       expiration: 171708,
       name: "pinblv.chain",
       winning_bid: "53994045000000004096",
       winning_bidder: "ak_jnUPoUBcnLXe1JXhisuxstQXn8TYmjh7j6f1dcSf76CxoK8BQ"
     },
     %{
       expiration: 171775,
       name: "silwwri.chain",
       winning_bid: "40561631965968752640",
       winning_bidder: "ak_LXrkuVQsU8Va2BxZJYiDdNQyE3oMuUVgxfYGdEbmXFWE7mXXh"
     },
     %{
       expiration: 171808,
       name: "bfitb.chain",
       winning_bid: "87364200000000000000",
       winning_bidder: "ak_2d4PJbgi2wpGD5evx2FmN9BHWdGcFRQsGGZ3cHVt7FQovnMzCn"
     },
     %{
       expiration: 171818,
       name: "icfpq.chain",
       winning_bid: "91732410000000008192",
       winning_bidder: "ak_dwDCK2X9PdjNs5mYmiJT2pShwnfwKKT3rcvuep6w7KMxWKT87"
     },
     %{
       expiration: 172051,
       name: "oiszmnp.chain",
       winning_bid: "36790595887500001280",
       winning_bidder: "ak_YtvjXxEmmMxog9QXpkXC7YUstL3vzmXkugho5Xv7JtML3yw3u"
     },
     %{
       expiration: 175964,
       name: "bmhkrp.chain",
       winning_bid: "51422900000000000000",
       winning_bidder: "ak_23XqqJaRuURJAhkxFZYQkSk4MPCoyKMF2WKPqKdmyHCbYCwH66"
     },
     %{
       expiration: 175968,
       name: "gjaakbq.chain",
       winning_bid: "31781100000000000000",
       winning_bidder: "ak_23XqqJaRuURJAhkxFZYQkSk4MPCoyKMF2WKPqKdmyHCbYCwH66"
     },
     %{
       expiration: 176327,
       name: "jzcov.chain",
       winning_bid: "91732410000000008192",
       winning_bidder: "ak_2CyikaA9t4SS2nNQBSbyqbhtU33vDK2kkyvCHfib512nNgrHxG"
     },
     %{
       expiration: 176526,
       name: "banana.chain",
       winning_bid: "51422900000000000000",
       winning_bidder: "ak_essw23rv1LdefJReNpoR5wiwtio44rqMdZEMf75F3Vsozg71M"
     },
     %{
       expiration: 186525,
       name: "h.chain",
       winning_bid: "570288700000000000000",
       winning_bidder: "ak_5pFCSwtTsgqixwWvFizDNmB6DvxFLKjeZWsUG83ajSZyio4DK"
     },
     %{
       expiration: 186575,
       name: "e.chain",
       winning_bid: "598803135000000069632",
       winning_bidder: "ak_2ZLiTkq5zVJ1MHEeHqg7arqSEVnCeVEMmdPCf2YUqBsfLQqv1e"
     },
     %{
       expiration: 186664,
       name: "r.chain",
       winning_bid: "628743291750000099328",
       winning_bidder: "ak_2eV3eXkLaSmVY8s2fAPFUzVwGbDSKAxXDRpLWxJaMAiDZK3Rds"
     },
     %{
       expiration: 191198,
       name: "cgx.chain",
       winning_bid: "250000000000000000000",
       winning_bidder: "ak_2swhLkgBPeeADxVTAVCJnZLY5NZtCFiM93JxsEaMuC59euuFRQ"
     },
     %{
       expiration: 191407,
       name: "ae.chain",
       winning_bid: "400000000000000000000",
       winning_bidder: "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc"
     }
   ]}
  """
  @spec get_active_name_auctions(Client.t(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_active_name_auctions(%Client{middleware: connection}, opts \\ []) do
    Middleware.get_active_name_auctions(connection, opts)
  end

  @doc """
    Gets the count of  currently active name auctions

    Example:
    iex()> AeppSDK.Middleware.get_active_name_auctions_count client
    {:ok, %{count: 21, result: "OK"}}
  """

  @spec get_active_name_auctions_count(Client.t(), list()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_active_name_auctions_count(%Client{middleware: connection}, opts \\ []) do
    Middleware.get_active_name_auctions_count(connection, opts)
  end

  @doc """
  Gets active names.

  Example:
  iex()> AeppSDK.Middleware.get_active_names client, limit: 3, page: 1
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
  Gets all contracts

  Example

  iex()> AeppSDK.Middleware.get_all_contracts client
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
     %{
       block_height: 163465,
       contract_id: "ct_p8toJDcpozCD2CVgiUcufJb8L5vvaMJRTyXZMjLosoVngRHbi",
       transaction_hash: "th_2mvD616VyRxxMJrHkBeE5jmePAHaGZLnVBGCKaudR3JY6bGEYZ"
     },
     %{
       block_height: 163407,
       contract_id: "ct_cPhX7ARRcyAjKQc6XponsjperT28UMibEPU5T1jKw1JMD1zE6",
       transaction_hash: "th_2oFzLVdQCKXq853EodkoS1DkLTQWZmEnQSgoQ9Zea2pQQfTERa"
     },
     %{
       block_height: 163390,
       contract_id: "ct_2eoh958X9GGSWCYDKauJULBKoDodMqkNrTS2gcJTsADC8EYNHF",
       transaction_hash: "th_2rn9nvgzZ5yw7qaHdF24qDM71ASUN36iLmRei7NWTfb5NvGdrH"
     },
     %{
       block_height: 163111,
       contract_id: "ct_2SDH77AMgUqxdZf42ktnknqaT1jKRwD3frMk72tp7SryYfkM4f",
       transaction_hash: "th_371CwrmcXeTwm5PKWj8pKb7kjeAy6swGmmjYEXbxCpbThEoCr"
     },
     %{
       block_height: 163092,
       contract_id: "ct_vJFvqE8BzsaJr5j8BoUNGbGnujNMzYSxL6jymedCxu6b62dHY",
       transaction_hash: "th_BYvecSNbTsJRJMD1T8M93AETHQZU9tCtyfcj94sLzAeSWeRQW"
     },
     %{
       block_height: 163088,
       contract_id: "ct_2QzUBjodDWmrjcgBmZHu2CTWSS66vpLvUt1d68xkW54a6QhjpD",
       transaction_hash: "th_25UttfiU5XrZR8ksL1FxKMQQiLoWq1YaCQ8vEDYGw1FLUqkFpT"
     },
     %{
       block_height: 163075,
       contract_id: "ct_2vwssFp5KMyqt6p5ZbzWK4Pnn3WSViPPJT3x8hoabcLjveehxE",
       transaction_hash: "th_2HUgMGSkZ7JKevNWhNeSX4s6FSsHG6fb6Adg7kjyR6VX6UgHvd"
     },
     %{
       block_height: 162780,
       contract_id: "ct_vL33Dm3B8ky8QSPrexQXBkDoEekdftTrcUr5nGUmwGMEfzwAA",
       transaction_hash: "th_2k1cURgQ1k6MLfww49EPjoGQdBj1xWHqNofw67NHdiiVT35v12"
     },
     %{
       block_height: 162765,
       contract_id: "ct_2a7YxS5HPWErCkzLieRTke1VGkr7diB8WQ2MmsjChVc2JtSQTY",
       transaction_hash: "th_TEz6HnkrqriupnShWfATMYppQWHQsn1ACbqVpj76u3zWScq7a"
     },
     %{
       block_height: 162765,
       contract_id: "ct_2puBRKxDptCMTjRBeU9ueHESQ81J68cyYJSaXz92BHekhMga4y",
       transaction_hash: "th_2sqz2DuJXf1gZaAc9Ru7pnXEFnW9d5U46y6cV63yeY8NkxpLoR"
     },
     %{
       block_height: 162758,
       contract_id: "ct_srsoDPb8HqkYfhPPbkqFdfLqtLjQRhpjUYpFnhi4Ui2J1zAzP",
       transaction_hash: "th_4xtzwQdvuBHNufkVQkHfNjBFuTpiDGNxVdt5gmLYHvdMKuVW8"
     },
     %{
       block_height: 162758,
       contract_id: "ct_2HkZ4eqAwNQtjf56qh1TLfhxVvRAsq8BLVZwrAN5Ut7pPKwGub",
       transaction_hash: "th_2fTQHny4WVzDHptWcyAz4ABKAzQQzrGq416WoppgRf965FSydt"
     },
     %{
       block_height: 162724,
       contract_id: "ct_EjezetXBqbAkAZkNjXDC45KtdPaqnU3yB2B9pV5sEsboGQ2Cs",
       transaction_hash: "th_fzWK1pAd1Szh6zjQtjDirTuwYrCmfJA31s6YpiaEU4sBFeCSV"
     },
     %{
       block_height: 162723,
       contract_id: "ct_yFhup2LjkC5FAkzD1zUSEeQKtMtoVrZa4GsQL4k25F3Up9E2b",
       transaction_hash: "th_2g2wDJb8XEkNPsqGPjHxy3J75Rm7yTaN9fCufsRxGVWvKpQJN9"
     },
     %{
       block_height: 162723,
       contract_id: "ct_2ncdURdXqy6cuu6q3UcqF3xv9DP1MimKoEuZxUzcJTps9xyjSU",
       transaction_hash: "th_2G8saEiGUYpgHKnyvSam1DjLgBtrrPM5cbXXhv1LYWnqPPvCJf"
     },
     %{
       block_height: 162723,
       contract_id: "ct_2uZcmKjitX3QEwY3TyfCYUTTMHDB3X8EW8C8ZC7mD3pg1T9LTH",
       transaction_hash: "th_mvxAUKSvYV3CJegv2H5PQFZWySpj3uDPAyJMuPQvtzpABW5uM"
     },
     %{
       block_height: 162720,
       contract_id: "ct_wg54TM7tAT7g8MnzQm35y2aLYncxNdK2LiXwTehZatqbxzQii",
       transaction_hash: "th_nER59DSBeJ7MuJYXsrhVVZqR42EC1HuMtvHneeRT6qdhUPUSU"
     },
     %{
       block_height: 162717,
       contract_id: "ct_td6da2qzNNGmQw61YREff9sLHXdiekXkWfk7TgsyrWwH4gfvD",
       transaction_hash: "th_9SRhBHYgzBeR1C7rgPQz8JTvoqfUXX7mC6GRqaN7jui8YhQAz"
     },
     %{
       block_height: 162717,
       contract_id: "ct_irqs9z5HEAVCT6QDEEqmh1vUBw56CdCueGZU2XMRNkCMb9puA",
       transaction_hash: "th_peHcVCsVWCpYDLJTQcAZnrXqMHfNPjJZSZhjwKTDemmC35vT6"
     },
     %{
       block_height: 162716,
       contract_id: "ct_2ZjquHqR9XrmFxEJ7CnwGZQxbg4jkpC4jsBW8E35nkcLtAxvWr",
       transaction_hash: "th_27i6ksYDc9K9rvWgRzsTPrxQQqyjmbH6cqdzaMmJzEdx5FcVve"
     },
     %{
       block_height: 162713,
       contract_id: "ct_2XpGWEssxyv44ySJ5mwC5MZLPPS6ReWRYT7CgUubRJVzNv3Sc3",
       transaction_hash: "th_2SkDv58FJcYVtk8h4WH7zmbfcKx32gnD8zEhEX7L1cyNNxPeTD"
     },
     %{
       block_height: 162713,
       contract_id: "ct_2qKipD6zG23k4JS1ZxU3NTn9yJ7y5ewuhw15qvisphhvi8v3ja",
       transaction_hash: "th_gS1SRLq4nqt1nHGGSHgK9ik6jiDd3q5rz3Y1E7rg4Ri4sb8J1"
     },
     %{
       block_height: 162711,
       contract_id: "ct_28VUQ3RrUK9fe8wVSg2MgGiGXFqWpHGo7NDkpTwTyEmCqrEXdc",
       transaction_hash: "th_2gh4gkF9eNdjYs173kNXmwsZvStX2vycRXc9AgqbH6bhpddKPR"
     },
     %{
       block_height: 162709,
       contract_id: "ct_4wS5TxV4WAZsudy1RMTx7fCKkhRHUEQcnPcC9aSAH63He3yk1",
       transaction_hash: "th_Jy1huAFrqoq1hC5AaTqGQZz6wcxfXLYGES2asKdjyNG9B71vZ"
     },
     %{
       block_height: 162707,
       contract_id: "ct_1NRtwsBpA2ppawWMx6u3pjtfrg6N7t27FV2Xj7aCJSEKA9vFT",
       transaction_hash: "th_2Pyz93WzA2pZvWqA6AV67qxBRDXLrNzGugwQxnFCk2hyfCjVx1"
     },
     %{
       block_height: 162704,
       contract_id: "ct_2Tp7kHxvFJGngP1zcoEPtohfD6UG78cVCmtLaa76uudK2eSjMU",
       transaction_hash: "th_2Fb3ciCD6jAsmJMRALCxcdjQ3ioeEwcC6HNQ62p6qg8nSPcFr4"
     },
     %{
       block_height: 162704,
       contract_id: "ct_aTNqwuZxjvdkd7zyKGETZ3hPj8aWwDeXMa4tPieaWnseHGxjn",
       transaction_hash: "th_1FScVsf8ZsvhFQ2GRF8NZHpjoGdiMeZPC1UYFZ2aSvFXnzWHq"
     },
     %{
       block_height: 162703,
       contract_id: "ct_3Ak6DKiug1MjAMh55nQQFNSp89Tg7XQZ6EJeX5Q2Rnd4mSyGv",
       transaction_hash: "th_2MpmVoe8zS9CGVDbqA5y5JhftKsTTY24hQL9CQzsz5PiD1q9b7"
     },
     %{
       block_height: 162700,
       contract_id: "ct_2gzNSx7nEGxBjry3esaCsz48WeUHadMYvJGnhM55a3cZEhuxPr",
       transaction_hash: "th_2jeyjJraeLLLciHPpQSPN4TrZKcRXc6t969bjAgXu7TPXB6CJB"
     },
     %{
       block_height: 162700,
       contract_id: "ct_TDmU96hAnpirR4UeJBH1J7AAt6xsxnBwRoZjG5NefMhG827fv",
       transaction_hash: "th_2JeDxPt72YbNznt5TMJRD9USbWJ56u9Ure3E9wfKtsErTXm2MZ"
     },
     %{
       block_height: 162700,
       contract_id: "ct_2Su4WEDtfYS5AmAsqapUQpK9Fosbg2qQdWfVFRj6AiWPGGEKHs",
       transaction_hash: "th_2sUY4SjWirLr9zL7D3k4gg8m1WLRM9bHyPGCkznDQZk6SZwg5u"
     },
     %{
       block_height: 162700,
       contract_id: "ct_2gcvU8FWhLTqSbsNbtzChwgonXmMPm6qN55NBzip1VLZ29ekSP",
       transaction_hash: "th_2tiE21a2piAiQBZXyBjme19W4yrTAd34hfj43X6x6aRzbcTtdM"
     },
     %{
       block_height: 162697,
       contract_id: "ct_2Pdeg2ujE3qCYhRA2suoTeDWyX64k4TM8JF73tzWtB4QcmBury",
       transaction_hash: "th_k3hQ1oojCjnUX4Yg2AXjo2VQ2DtCLETGVQx6csEQcBw45Sowq"
     },
     %{
       block_height: 162697,
       contract_id: "ct_2r4iaQ9FADtCVuk9prMdBzgGuM45vJRj1D5BsDkxPLmYNraLM8",
       transaction_hash: "th_2iesFLAeGWjv8Yo8cf48CUha9LLXvTkii1LXepzjKarwuLks8P"
     },
     %{
       block_height: 162697,
       contract_id: "ct_2EFL4Z5afKBkiHc7CpNWevrb1CbPogoATdTQjanyhtj2vtdJi",
       transaction_hash: "th_2i2GmaATaPMqZiGFSCHiR6CYtMoej2VguqQ5YWi1994tVwZuKZ"
     },
     %{
       block_height: 162696,
       contract_id: "ct_W1NCF6EvaK7Rr3AuYAEPGTfqrFHMC3mo9M3fnbfePRqnshMP6",
       transaction_hash: "th_eXqWFw7bXq6vXUqeoAx9PidcRzDPVuT7UsDMQYL8nyHYtpXhu"
     },
     %{
       block_height: 162690,
       contract_id: "ct_2mbuYyr5qSCz9uswG5tSNAQFNgSnUE5aKC97BBZ2nXeLtBeCUf",
       transaction_hash: "th_mPDCkYMMmB9gvVW1oznYmhGUHa5t9b7RrAr4twdUFJavkLr59"
     },
     %{
       block_height: 162688,
       contract_id: "ct_TfQnTBMge3UJSa6G7HVNb2ijqFzjPr14KqDuKwDSwbNSA3uLz",
       transaction_hash: "th_JQcfnq8Tcy83GjWxAF4icbb3CMtyjvKjuzS57RENVjp7C1p3r"
     },
     %{
       block_height: 162688,
       contract_id: "ct_24cVC7bxwTD4X2c9jJ6q8UQ3D6UhKMC4rGwvE6mbfkaEdRM9WR",
       transaction_hash: "th_2WEHdhWZJViSr2rhV4o3rPyV7cWdtKtB5JTVHNZ1LYkPYfGF6g"
     },
     %{
       block_height: 162688,
       contract_id: "ct_jCnywVujtyvgBkSRLHyhtmJ9ZoufYW2THq38Dn5ShrxKA5VqT",
       transaction_hash: "th_2fynizF6ArXnqJyxPRNmVFizqCo1H3Yg8qMgqHp1A9Tr2JNm6F"
     },
     %{
       block_height: 162686,
       contract_id: "ct_21qZvJ6iTnfNtEJBrSeox4RvbLbFwVRJU55EwhDQv1w4XezLyc",
       transaction_hash: "th_2fKee8SMHvwbhmgksJPrg5d6LdJtDiB1o3AQwpma5aX35VBe3G"
     },
     %{
       block_height: 162682,
       contract_id: "ct_kRsxSEnMQ9XrL1Qfct9UUBPDejTjB8sC8Kqf9Y4QvyrbFgNdE",
       transaction_hash: "th_2ef2Dm6srHaBwdeQUWjx4hArSV4TByyNE8k73U6sFb3ZiApYVK"
     },
     %{
       block_height: 162676,
       contract_id: "ct_2UKwjUSM4BLkfxJenuBtXH5L27v7NYAfyiECtHQkPYVupymmmJ",
       ...
     },
     %{block_height: 162675, ...},
     %{...},
     ...
   ]}
  """
  @spec get_all_contracts(Client.t()) :: {:ok, list()} | {:error, Tesla.Env.t()}
  def get_all_contracts(%Client{middleware: connection}) do
    Middleware.get_all_contracts(connection)
  end

  @doc """
  Gets all names

  iex()> AeppSDK.Middleware.get_all_names client, limit: 3, page: 1
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
    Gets all currently active oracles
    iex()> AeppSDK.Middleware.get_all_oracles client, limit: 3, page: 1
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
  Gets current chain size

  Example:
  iex()> AeppSDK.Middleware.get_chain_size client
  {:ok, %{size: 2231715109}}
  """

  @spec get_chain_size(Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_chain_size(%Client{middleware: connection}) do
    Middleware.get_chain_size(connection)
  end

  @doc """
  Gets channel transactions by channel id

  Example:
  iex()> AeppSDK.Middleware.get_channel_txs client, "ch_JP22NWe19jPauZ67yNANC233oCgMnXpJ8JFMvRa29nnU4KSEb"
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
  Gets currently available middleware compiler's version

  Example:
  iex()> AeppSDK.Middleware.get_compilers client
  {:ok, %{compilers: ["4.0.0"]}}
  """
  @spec get_compilers(Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_compilers(%Client{middleware: connection}) do
    Middleware.get_compilers(connection)
  end

  @doc """
  Gets contracts calls by contract id

  Example:
   AeppSDK.Middleware.get_contract_address_calls client, "ct_2ofvJh4ZpGLJdB25cGit41bC42vcKbC5vi8T9Js6EREe24RbfN"
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
  Gets contract tx information

  Example:
  iex()> AeppSDK.Middleware.get_contract_tx client, "ct_2ofvJh4ZpGLJdB25cGit41bC42vcKbC5vi8T9Js6EREe24RbfN"
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
         code: "cb_+QYFRgOgkuHoq7A/Qia27eQYdgtX/QB8xZzsLJnlVrYIoSkA4yjAuQXXuQQ4/gf80LEANwBHAH0AAP4NrXMdADcANwAMA/8MAoIpDAoaAoIBAz/+IDlsXAA3AEcAVQAA/iHwCd4CNwEnRwAXMwQABwwKNQYAADYGAgBVACAIAAcMCBoJAAIGAwAAAQP/AQN//iKbVT8ANwAXKCwKgiAwfwcMEgwDUUdhbWUgYWxyZWFkeSBzdGFydGVk+wAaAm+CJs8MA2+IDeC2s6dj/8ALACAABwwQDANFTm90IGVub3VnaCB0b2tlbnP7ABoCb4ImzwwDfygsCIICAxFb6ABtIAAHDA4BA38oLAiCVQA0AAwCgikMCBoCggED/wwDPwYDCAwDPwYDBP4p0PgzADcAZwc3A3cHJ3dVAH0AIAAHDAYMA3VPbmx5IGEgYm9zcyBub3cgdGhlIHF1ZXN0aW9uc/sAGgJvgibPKCwEggAMAz8GAwT+NIEJCAI3AkcAJ0cAJ0cAMwQCBwwKNQYAAjYGAgIgGAAABwwIGgkCAgYDAAABAgI4AAD+N7mjAgA3Agd3hwI3ADcBNwN3Byd3KCwMgiAwfwcMGAwDQVNvcnJ5LCBnYW1lIG92ZXL7ABoCb4ImzygsCoIgMP8HDBYMA21Tb3JyeSwgZ2FtZSBoYXMgbm90IHN0YXJ0ZWT7ABoCb4ImzwwBAgwBAAIDEXxkgqomAAcMEigsBIIxACAQAAcMEBQ0AAIoLASCKwBE/CMAAgICAAwD/wwCgikMDBoCglMAVQBlACgsBIIrEABE/CMAAgICACgsCIJVAAIDETSBCQgMAoIpDAgaAoJE/CMAAgAAAAwDPwYDCAwDPwYDBP5EsInoADcAJ0cAKCwIggD+RNZEHwA3ADcADAMCDANUDAN5V2hhdCBpcyB0aGUgY2FwaXRhbCBvZiBVcnVndWF5DAMCOAA0DCFOZXcgWW9yazQMGUJlcmxpbjQMFVZhZHV6NAwpTW9udGV2aWRlbycMBioCACoALTACLfgAAilNb250ZXZpZGVvOAAMA38MA38nDA4aAoIBAz/+W+gAbQI3ASdHABczBAAHDAo1BgAANgYCAFUAIAgABwwIGgkAAgYDAAABA/8BA3/+ZKDpUgA3AQc3A3cHJ3coLASCKxAAAP5uT9D7ADcBBwcMAQAMAoIpDAIaAoIBAQD+fGSCqgA3Agd3FygsBoIrEAAgEAIA/n1yCuQANwAHKCwCggD+rB35kwA3ABcoLAyCAP6zhfzjADcAFygsCIIEAxEh8Ane/rQQWDcANwN3dyd3NwB9AFUAIAAHDAYMA1VZb3UgYXJlIG5vdCB0aGUgQm9zcy77ABoCb4ImzygsAIIUMgICGgoEggwCAgwBAAwCAgwBBCcMBiguBgYEKCwEBC0gAi1oBgICDAIEKQwGKQwEKQwAGgKCAQM/DAM/BgME/sqgibAANwAXKCwKggD+16P7sQA3ABdVAH0AIAAAuQGWLxQRB/zQsSVnZXRfb3duZXIRDa1zHSlzdGFydF9nYW1lESA5bFw1cmV0dXJuX2NhbGxlchEh8AneQS5FbWluLmlzX2luX2xpc3QRIptVPyFyZWdpc3RlchEp0PgzNWdldF9xdWVzdGlvbnMRNIEJCHEuRW1pbi5kZWxldGVfZnJvbV9wYXJ0aXBhbnRzETe5owItbWFrZV9hbnN3ZXIRRLCJ6E1yZXR1cm5fcGFydGljaXBhbnRzEUTWRB8RaW5pdBFb6ABtZS5FbWluLmNoZWNrX2lmX3JlZ2lzdGVyZWQRZKDpUjFnZXRfcXVlc3Rpb24Rbk/Q+zlhZGRfdGVzdF92YWx1ZRF8ZIKqYWlzX3RoaXNfdGhlX3JpZ2h0X2Fuc3dlchF9cgrkPXJlYWRfdGVzdF92YWx1ZRGsHfmTPWlzX2dhbWVfc3RvcHBlZBGzhfzjNWlzX3JlZ2lzdGVyZWQRtBBYNzFhZGRfcXVlc3Rpb24RyqCJsD1pc19nYW1lX3N0YXJ0ZWQR16P7sSFpc19vd25lcoIvAIU0LjAuMAAu0vNH",
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

  Gets current transactions count

  Example:
  iex()> AeppSDK.Middleware.get_current_tx_count client
  {:ok, %{count: 3563570}}
  """
  @spec get_current_tx_count(Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_current_tx_count(%Client{middleware: connection}) do
    Middleware.get_current_tx_count(connection)
  end

  @doc """
  Gets generations by provided range
  iex()> from = 1
  iex()> to 3
  iex()> AeppSDK.Middleware.get_generations_by_range client, from, to
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
  Gets height by provided timestamp in milliseconds

  Example:
  iex()> AeppSDK.Middleware.get_height_by_time client, 1572883000000
  {:ok, %{height: 163532}}

  """
  @spec get_height_by_time(AeppSDK.Client.t(), integer) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_height_by_time(%Client{middleware: connection}, milliseconds)
      when is_integer(milliseconds) do
    Middleware.get_height_by_time(connection, milliseconds)
  end

  @doc """
  Gets current middleware status
  Example:
  iex()> AeppSDK.Middleware.get_middleware_status client
  {:ok,
   %{OK: true, queue_length: 0, seconds_since_last_block: 178, version: "0.10.0"}}
  """
  @spec get_middleware_status(AeppSDK.Client.t()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_middleware_status(%Client{middleware: connection}) do
    Middleware.get_mdw_status(connection)
  end

  @doc """

  Gets name auction bids by address

  Example:
  iex(65)> AeppSDK.Middleware.get_name_auctions_bids_by_address client, "ak_bpN6hPjRg7giYu2ChXDPK7aLP2WPw3nzFFkNouLoGt33WsWu9"
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
  Gets name auction bids by name

  Example:
  iex()> AeppSDK.Middleware.get_name_auctions_bids_by_name client,  "valiotest123.chain"                         {:ok,
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
  Gets name information by account address

  Example:
  iex()> AeppSDK.Middleware.get_name_by_address  client,  "ak_DzELMKnSfJcfnCUZ2SbXUSxRmFYtGrWmMuKiCx68YKLH26kwc"
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

  Gets oracle data by oracle id

  Example:
  AeppSDK.Middleware.get_oracle_data client,  "ok_2hzMeKfxSTg3QBiin34PA1pzQwscULv3RcNuxMasaKzoUSH53o"
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
  Gets miner reward at given height

  Example:
  iex()> AeppSDK.Middleware.get_reward_at_height client, 10234                                                   {:ok,
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
    Gets size of a blockchain at given height
  Examples:
  iex()> AeppSDK.Middleware.get_size_at_height client, 10234
  {:ok, %{size: 1220968}}
  """
  @spec get_size_at_height(Client.t(), integer()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_size_at_height(%Client{middleware: connection}, height) when is_integer(height) do
    Middleware.get_size_at_height(connection, height)
  end

  @doc """
  Get transactions made between 2 addresses
  Example:
  iex(80)> AeppSDK.Middleware.get_tx_between_address client, client.keypair.public, client.keypair.public
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
       },
       %{
         block_hash: "mh_Va7YE5ehhocqw26UisnNRM9uPcQDq1gRNg9yHLCi3yACJKCcW",
         block_height: 162082,
         hash: "th_25mu1NscdeDJf6Fe2u29m5P8r8vqxnWhgYNt74drgRLaub6yCy",
         signatures: ["sg_Z1dPF1Rp4FUHF41GkdjkcREfJdoaxFSuWhnRiAaPdCUEKtBMQp6eRiJnigzTABZHfrTsXmvndGhybNJma5XwFGRTcgeky"],
         tx: %{
           amount: 10000,
           fee: 16700000000000,
           nonce: 6,
           payload: "ba_Xfbg4g==",
           recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
           sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
           type: "SpendTx",
           version: 1
         }
       },
       %{
         block_hash: "mh_4hjTaRsxCfv6MHvdzZRFqJDo8Lb3qybGJRrZJQd5gLuK3oUgp",
         block_height: 162058,
         hash: "th_2oNd28EN9JSY5F5EfhvZSZYNPti6MPmTCffR5BjUPoMncQSg2i",
         signatures: ["sg_LvjaNjLJS61G4bcfc8JaK4rhFidA2R1xaRCqUbjgV8X4JinbZ1vQToD9UngQErYuSxvkC7vxUMxE15DsS69xeGwbRxdju"],
         tx: %{
           amount: 10000000,
           fee: 16720000000000,
           nonce: 5,
           payload: "ba_Xfbg4g==",
           recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
           sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
           type: "SpendTx",
           version: 1
         }
       }
     ]
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

  Example:
   AeppSDK.Middleware.get_tx_by_account client, client.keypair.public
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
     },
     %{
       block_hash: "mh_Va7YE5ehhocqw26UisnNRM9uPcQDq1gRNg9yHLCi3yACJKCcW",
       block_height: 162082,
       hash: "th_25mu1NscdeDJf6Fe2u29m5P8r8vqxnWhgYNt74drgRLaub6yCy",
       signatures: ["sg_Z1dPF1Rp4FUHF41GkdjkcREfJdoaxFSuWhnRiAaPdCUEKtBMQp6eRiJnigzTABZHfrTsXmvndGhybNJma5XwFGRTcgeky"],
       time: 1572619639897,
       tx: %{
         amount: 10000,
         fee: 16700000000000,
         nonce: 6,
         payload: "ba_Xfbg4g==",
         recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         type: "SpendTx",
         version: 1
       }
     },
     %{
       block_hash: "mh_4hjTaRsxCfv6MHvdzZRFqJDo8Lb3qybGJRrZJQd5gLuK3oUgp",
       block_height: 162058,
       hash: "th_2oNd28EN9JSY5F5EfhvZSZYNPti6MPmTCffR5BjUPoMncQSg2i",
       signatures: ["sg_LvjaNjLJS61G4bcfc8JaK4rhFidA2R1xaRCqUbjgV8X4JinbZ1vQToD9UngQErYuSxvkC7vxUMxE15DsS69xeGwbRxdju"],
       time: 1572615226471,
       tx: %{
         amount: 10000000,
         fee: 16720000000000,
         nonce: 5,
         payload: "ba_Xfbg4g==",
         recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         type: "SpendTx",
         version: 1
       }
     },
     %{
       block_hash: "mh_ZmYRqpdUFxYQGYpYqMVcsAXQ24Ex6aLYAmQcvudk2fWD4qKgk",
       block_height: 162058,
       hash: "th_2P8YBpxRugvME772MCpA79kRmFqKfeLHfDs2AWViRPhX66AGEv",
       signatures: ["sg_FHVeVfL3cMcgnLGkdy77BvqgAGPSJCti27RfVD8ee684dVKTAfYR3LVxWgAAfq9jFDhkQ67PoZz3s44a26A678JdiwARe"],
       time: 1572615193471,
       tx: %{
         amount: 10000000,
         fee: 16720000000000,
         nonce: 4,
         payload: "ba_Xfbg4g==",
         recipient_id: "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv",
         sender_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         type: "SpendTx",
         version: 1
       }
     },
     %{
       block_hash: "mh_vx6XCDruee3ZUS7TNDu6UHR9rc3cH2bhkB1ssQ4VcBuMPxJM2",
       block_height: 160992,
       hash: "th_L6USuQGUnVCiFH8v8vJetZJH4qQ4AcLECySgiyz9GcHcYAWvY",
       signatures: ["sg_VHJvSJKTHJB4cMvVASNAkX5H5AamBhFDx33yHqGgdMRpaJ7BDgJWiN3CyhCHdsEYWx8Tj5o3JY5fAb6UZkopaFD3rDNJ5"],
       time: 1572425993865,
       tx: %{
         account_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         fee: 17640000000000,
         name: "a1234567890aseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef.chain",
         name_fee: 300000000000000,
         name_salt: 118897737954584115,
         nonce: 3,
         type: "NameClaimTx",
         version: 2
       }
     },
     %{
       block_hash: "mh_2VjhPSFrg4Xga95UKR7WFZhFRegjT8pzghcFjAGp4XX2C698fp",
       block_height: 160991,
       hash: "th_mAE6TqTtmaCipiaJQJifJAPT8ZQvaSZQRrdrMNqQh7ytAxRbJ",
       signatures: ["sg_UhuD6Cue1aba4gH1cJ9kceW6M5RaYxzXobMWvAugWHgbHNyZiz1ju41scZJGTzJaMEFvorDeo4G6hAw7DhKohvaHckXcm"],
       time: 1572425959737,
       tx: %{
         account_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         commitment_id: "cm_CLE8U4kRvqEJGKKwFG5axdUGmrgwmc9o3bGA8VZWjNRzx9jWP",
         fee: 16620000000000,
         nonce: 2,
         type: "NamePreclaimTx",
         version: 1
       }
     },
     %{
       block_hash: "mh_rbraqC4aZZ3b73twhkqd46F7tdsy7Y1ZTMeENWG7mneHGpHfo",
       block_height: 160991,
       hash: "th_X4wLTxJeESvK85aZxPxAcAZiDpk1jY3WoCJEdtLZFjfUrJ3Je",
       signatures: ["sg_RxfuVWbn9M6D7djiRmQ7EbbXESuB9bTXqYY1zArmfnBSbh7mmu99JGYD7Ryvaoocc5eaGqDd2qe6f3P7WwhP53NrWdwNA"],
       time: 1572425932737,
       tx: %{
         account_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         commitment_id: "cm_2NctiEJBxxLg2MqbpWsG8ym4cG41uQ4hzLb8MrRJdf9JUqXrMT",
         fee: 16620000000000,
         nonce: 1,
         type: "NamePreclaimTx",
         version: 1
       }
     },
     %{
       block_hash: "mh_nKXBqayaMjXEpxuEavHCATquM7X9478SeAw4Gv5mRNWfFsYPk",
       block_height: 160976,
       hash: "th_2JTEUKSzQZNsvuHqCyEVoAxz9728aSomLzYMoNDXDZ9y2d562T",
       signatures: ["sg_WPnm73g316UX8dZCGx34vf4gdm6Honc19dBFauM1EKFFbbmETatiDuGMwAK6Du5B3yTTgDZFmjpCsahZc6QobAw77V8EP"],
       time: 1572422898054,
       tx: %{
         amount: 5000000000000000000,
         fee: 17040000000000,
         nonce: 9563,
         payload: "ba_RmF1Y2V0IFR4tYtyuw==",
         recipient_id: "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7",
         sender_id: "ak_2iBPH7HUz3cSDVEUWiHg76MZJ6tZooVNBmmxcgVK6VV8KAE688",
         type: "SpendTx",
         version: 1
       }
     }
   ]}
  """
  @spec get_tx_by_account(Client.t(), binary, keyword) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_tx_by_account(%Client{middleware: connection}, account, opts \\ [])
      when is_binary(account) do
    Middleware.get_tx_by_account(connection, account, opts)
  end

  @doc """
  Gets all transactions in between the given generation range

  Example:
  #TODO tomorrow

  """
  @spec get_tx_by_generation_range(Client.t(), integer(), integer(), list()) ::
          {:ok, list()} | {:error, Tesla.Env.t()}
  def get_tx_by_generation_range(%Client{middleware: connection}, from, to, opts \\ [])
      when is_integer(from) and is_integer(to) do
    Middleware.get_tx_between_address(connection, from, to, opts)
  end

  @doc """
  Gets transaction count by address

  Example:
  iex()> AeppSDK.Middleware.get_tx_count_by_address client, client.keypair.public
  {:ok, %{count: 9}}
  """
  @spec get_tx_count_by_address(Client.t(), binary, keyword) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_tx_count_by_address(%Client{middleware: connection}, address, opts \\ [])
      when is_binary(address) do
    Middleware.get_tx_count_by_address(connection, address, opts)
  end

  @doc """
  Gets transaction rate by provided date range

  Example:

  #TODO should be added tomorrow
  """
  @spec get_tx_rate_by_date_range(Client.t(), integer(), integer()) :: none
  def get_tx_rate_by_date_range(%Client{middleware: connection}, from, to)
      when is_integer(from) and is_integer(to) do
    Middleware.get_tx_rate_by_date_range(connection, from, to)
  end

  @doc """
  Searches for given name

  Example:
  iex()> AeppSDK.Middleware.search_name client, "valiotest123.chain"
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
  Verify a contract by submitting the source, compiler version and contract identifier

  Example:
  #TODO Tomorrow  AeppSDK.Middleware.verify_contract client, body: %{contract_id: "ct_mBpDYtSPVANfymGUfo55fciHBrX7X9SvwWxVZqrKLtC1zapfW", source: source, compiler: "4.0.0"}
  """

  @spec verify_contract(Client.t(), list()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def verify_contract(%Client{middleware: connection}, opts \\ []) do
    Middleware.verify_contract(connection, opts)
  end
end
