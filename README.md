## Omnichian kBTC
kBTC is backed 1:1 by BTC staked to the [Babylon Protocol](https://babylonscan.io/). The staker wallet is a 2-3 MPC wallet operated by Cobo, Kinza and Coincover (independent 3-rd party for emergency recovery), empowered by Cobo Technology.


## Stage 1 Launch 
Since Babylon would likely launch with small staking cap, Kinza would focus on prioritizing staking ratio on Babylon with user's deposit, thus withdrawal would **ONLY** be enabled once Babylon lift staking cap (neither time or quantity). Please deposit with caution.


## Babylon and any future BTC Staking Reward Distribution
All Babylon reward, except 10% withheld for the protocol's operation, would be distributed to kBTC depositor based on their time-weighed contribution. Specificially:

```sh
Assume Kinza as a protocol collectively earns 10000 Babylon Token(BBN). and there are three users, Bob, Alice, Ken:

1. Bob holds 1 kBTC for 10 days

2. Alice holds 0.5 kBTC for 30 days

3. Ken holds 10 kBTC for 0.5 days

```

A simple illustration can be done by dividing the reward pool by their sum product of:

```sh
time * unit of BTC 
``` 

There are `1 * 10 + 0.5 * 30 + 10 * 0.5 = 30 units`, splitting the total 9000 BBN (post-protocol fee), thus Bob would get 3000, Alice would get 4500 and Ken would get 1500 BBN respectively.


## Withdrawal Process
When users initiaite withdrawal through burning their kBTC, they automatically queue up for withdrawal. Kinza would then unbond the corresponding amount of BTC from Babylon to fulfil the request. User would need to wait a maximum of the unbonding period as specified in Babylon (to be announced). Kinza would keep a small amount of reserve to fulfil quick withdrawal but this would not be used as gaurantee on withdrawal cycle. 



## Deposit Fee
A small amount of fee (0.1%) would be deduced from the initial deposit to cover staking related cost incurred in the bitcoin network. This fee is immediately charged at each deposit by only minting 99.9% of the deposit amount to users in unit of kBTC.


## kBTC is an omnichain token, powered by Layerzero
The token natively supports cross-chain operations


## Repo based on Previous Work
[layerzero-starter-kit](https://github.com/e00dan/layerzero-starter-kit)
