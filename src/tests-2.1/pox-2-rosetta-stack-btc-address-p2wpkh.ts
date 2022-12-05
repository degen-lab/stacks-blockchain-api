import { testnetKeys } from '../api/routes/debug';
import { accountFromKey } from '../test-utils/test-helpers';
import { testRosettaStackWithBtcAddress } from './reusable-tests';

describe('PoX-2 - Rosetta - Stack with P2WPKH BTC address', () => {
  const account = accountFromKey(testnetKeys[1].secretKey);
  testRosettaStackWithBtcAddress({ account, addressFormat: 'p2wpkh' });
});
