package keeper_test

import (
	"testing"

	"cosmossdk.io/math"
	cosmostypes "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"

	appparams "github.com/neutron-org/neutron/v4/app/params"
	"github.com/neutron-org/neutron/v4/testutil/common/nullify"
	testkeeper "github.com/neutron-org/neutron/v4/testutil/dynamicfees/keeper"
	"github.com/neutron-org/neutron/v4/x/dynamicfees/types"
)

func TestConvertToDenom(t *testing.T) {
	k, ctx := testkeeper.DynamicFeesKeeper(t)
	params := types.DefaultParams()

	const atomDenom = "uatom"
	const osmosDenom = "uosmo"
	// adding additional denoms
	// Let's say:
	// 1 ATOM = 10 NTRN => 1 NTRN = 0.1 ATOM
	// 1 OSMO = 2 NTRN => 1 NTRN => 2 OSMO
	params.NtrnPrices = append(params.NtrnPrices, []cosmostypes.DecCoin{
		{Denom: atomDenom, Amount: math.LegacyMustNewDecFromStr("0.1")},
		{Denom: osmosDenom, Amount: math.LegacyMustNewDecFromStr("2")},
	}...)
	require.NoError(t, k.SetParams(ctx, params))

	for _, tc := range []struct {
		desc          string
		baseCoins     cosmostypes.DecCoin
		targetDenom   string
		expectedCoins cosmostypes.DecCoin
		err           error
	}{
		{
			// if i try to convert 10 NTRN to NTRN i must pay 10 NTRN
			desc:          "check NTRN",
			baseCoins:     cosmostypes.DecCoin{Denom: appparams.DefaultDenom, Amount: math.LegacyMustNewDecFromStr("10")},
			targetDenom:   appparams.DefaultDenom,
			expectedCoins: cosmostypes.DecCoin{Denom: appparams.DefaultDenom, Amount: math.LegacyMustNewDecFromStr("10")},
			err:           nil,
		},
		{
			// if i try to convert to non-existing denom, i must get an ErrUnknownDenom error
			desc:          "non-existing denom",
			baseCoins:     cosmostypes.DecCoin{Denom: "untrn", Amount: math.LegacyMustNewDecFromStr("10")},
			targetDenom:   "unknown_denom",
			expectedCoins: cosmostypes.DecCoin{Denom: appparams.DefaultDenom, Amount: math.LegacyMustNewDecFromStr("10")},
			err:           types.ErrUnknownDenom,
		},
		{
			// if i convert 10 NTRN to ATOM, i must get 1 ATOM
			desc:          "10 NTRN to ATOM",
			baseCoins:     cosmostypes.DecCoin{Denom: appparams.DefaultDenom, Amount: math.LegacyMustNewDecFromStr("10")},
			targetDenom:   atomDenom,
			expectedCoins: cosmostypes.DecCoin{Denom: atomDenom, Amount: math.LegacyMustNewDecFromStr("1")},
			err:           nil,
		},
		{
			// if i convert 0.5 NTRN to ATOM, i must get 1 ATOM
			desc:          "0.5 NTRN to ATOM",
			baseCoins:     cosmostypes.DecCoin{Denom: appparams.DefaultDenom, Amount: math.LegacyMustNewDecFromStr("0.5")},
			targetDenom:   atomDenom,
			expectedCoins: cosmostypes.DecCoin{Denom: atomDenom, Amount: math.LegacyMustNewDecFromStr("0.05")},
			err:           nil,
		},
		{
			// if i convert 0.5 NTRN to OSMO, i must get 1 TIA
			desc:          "0.5 NTRN to OSMO",
			baseCoins:     cosmostypes.DecCoin{Denom: appparams.DefaultDenom, Amount: math.LegacyMustNewDecFromStr("0.5")},
			targetDenom:   osmosDenom,
			expectedCoins: cosmostypes.DecCoin{Denom: osmosDenom, Amount: math.LegacyMustNewDecFromStr("1")},
			err:           nil,
		},
		{
			// if i convert 2 NTRN to OSMO, i must get 4 OSMO
			desc:          "2 NTRN to OSMO",
			baseCoins:     cosmostypes.DecCoin{Denom: appparams.DefaultDenom, Amount: math.LegacyMustNewDecFromStr("2")},
			targetDenom:   osmosDenom,
			expectedCoins: cosmostypes.DecCoin{Denom: osmosDenom, Amount: math.LegacyMustNewDecFromStr("4")},
			err:           nil,
		},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			convertedCoin, err := k.ConvertToDenom(ctx, tc.baseCoins, tc.targetDenom)
			if tc.err != nil {
				require.ErrorIs(t, err, tc.err)
			} else {
				require.NoError(t, err)
				require.Equal(t,
					nullify.Fill(tc.expectedCoins),
					nullify.Fill(convertedCoin),
				)
			}
		})
	}
}

func TestExtraDenoms(t *testing.T) {
	k, ctx := testkeeper.DynamicFeesKeeper(t)
	params := types.DefaultParams()
	expectedDenoms := make([]string, 0, len(params.NtrnPrices))
	for _, coin := range params.NtrnPrices {
		expectedDenoms = append(expectedDenoms, coin.Denom)
	}

	// default denoms
	denoms, err := k.ExtraDenoms(ctx)
	require.NoError(t, err)
	require.EqualValues(t, expectedDenoms, denoms)

	// additional denoms
	params.NtrnPrices = append(params.NtrnPrices, cosmostypes.DecCoin{Denom: "uatom", Amount: math.LegacyMustNewDecFromStr("10")})
	require.NoError(t, k.SetParams(ctx, params))
	expectedDenoms = make([]string, 0, len(params.NtrnPrices))
	for _, coin := range params.NtrnPrices {
		expectedDenoms = append(expectedDenoms, coin.Denom)
	}

	denoms, err = k.ExtraDenoms(ctx)
	require.NoError(t, err)
	require.EqualValues(t, expectedDenoms, denoms)
}
