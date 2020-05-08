import * as bitcoin from 'bitcoinjs-lib';
import {
  makeBtcFaucetPayment,
  getRpcClient,
  getFaucetWallet,
  getKeyAddress,
  getBtcBalance,
} from '../btc-faucet';

async function getBalanceWithWalletImport(address: string): Promise<number> {
  const client = getRpcClient();
  const walletName = `recipient_wallet_${address}`;
  await client.createwallet({ wallet_name: walletName });
  await client.importaddress({ address: address, rescan: true }, walletName);
  const getBalanceResult: number = await client.getbalance({ include_watchonly: true }, walletName);
  return getBalanceResult;
}

test('test btc faucet', async () => {
  const regtest = bitcoin.networks.regtest;

  const client = getRpcClient();

  const wallet = getFaucetWallet(regtest);

  // Mint btc to the faucet wallet address.
  await client.generatetoaddress({ address: wallet.address, nblocks: 110 });

  const btcToSend1 = 55.2;
  const recipientAddress1 = getKeyAddress(bitcoin.ECPair.makeRandom({ network: regtest }));
  const paymentResult1 = await makeBtcFaucetPayment(regtest, recipientAddress1, btcToSend1);
  expect(paymentResult1.txId).toBeTruthy();

  const btcToSend2 = 60.5;
  const recipientAddress2 = getKeyAddress(bitcoin.ECPair.makeRandom({ network: regtest }));
  const paymentResult2 = await makeBtcFaucetPayment(regtest, recipientAddress2, btcToSend2);
  expect(paymentResult2.txId).toBeTruthy();

  const btcToSend3 = 51.8;
  const recipientAddress3 = getKeyAddress(bitcoin.ECPair.makeRandom({ network: regtest }));
  const paymentResult3 = await makeBtcFaucetPayment(regtest, recipientAddress3, btcToSend3);
  expect(paymentResult3.txId).toBeTruthy();

  // Test balance with mempool transactions
  const fetchedBalance3 = await getBtcBalance(regtest, recipientAddress3);
  expect(fetchedBalance3).toBe(btcToSend3);

  // Mine some blocks
  await client.generatetoaddress({ address: wallet.address, nblocks: 10 });

  // Test that recipient addresses received btc
  const getBalanceResult1 = await getBalanceWithWalletImport(recipientAddress1);
  expect(getBalanceResult1).toBe(btcToSend1);

  const fetchedBalance1 = await getBtcBalance(regtest, recipientAddress1);
  expect(fetchedBalance1).toBe(btcToSend1);

  const getBalanceResult2 = await getBalanceWithWalletImport(recipientAddress2);
  expect(getBalanceResult2).toBe(btcToSend2);

  const fetchedBalance2 = await getBtcBalance(regtest, recipientAddress2);
  expect(fetchedBalance2).toBe(btcToSend2);
});
