import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib('ALGO');

const startingBalance = stdlib.parseCurrency(100);
const alicezAccount = await stdlib.newTestAccount(startingBalance);
const bobzAccount = await stdlib.newTestAccount(startingBalance);

const fmt = (amount) => stdlib.formatCurrency(amount, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
const alicezBalanceBefore = await getBalance(alicezAccount);
const bobzBalanceBefore = await getBalance(bobzAccount);

const alicezContract = alicezAccount.contract(backend);
const bobzContract = bobzAccount.contract(backend, alicezContract.getInfo());

const HAND = ['Rock', 'Paper', 'Scissors'];
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];

const Player = (Who) => ({
    ...stdlib.hasRandom,
    getHand: async () => { // to enforce timout
        const hand = Math.floor(Math.random() * 3);
        console.log(`${Who} played ${HAND[hand]}`);
        if (Math.random() <= 0.01) {
            for (let i = 0; i < 10; i++) {
                console.log(`  ${Who} takes their sweet time sending it back...`);
                await stdlib.wait(1);
            }
        }
        return hand;
    },
    seeOutcome: (outcome) => {
        console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
    },
    informTimeout: () => {
        console.log(`${Who} observed a timeout`);
    },
});

await Promise.all([
    alicezContract.p.Alice({
        ...Player('Alice'),
        wager: stdlib.parseCurrency(5),
        deadline: 10,
    }),
    bobzContract.p.Bob({
        ...Player('Bob'),
        acceptWager: (amt) => {
            console.log(`Bob accepts the wager of ${fmt(amt)}.`);
        },
    }),
]);

const alicezBalanceAfter = await getBalance(accAlice);
const bobzBalanceAfter = await getBalance(accBob);

console.log(`Alice went from ${alicezBalanceBefore} to ${alicezBalanceAfter}.`);
console.log(`Bob went from ${bobzBalanceBefore} to ${bobzBalanceAfter}.`);
