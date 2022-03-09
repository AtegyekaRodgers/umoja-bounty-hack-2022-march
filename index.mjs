import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib('ALGO');

const startingBalance = stdlib.parseCurrency(100);
const alicezAccount = await stdlib.newTestAccount(startingBalance);
const bobzAccount = await stdlib.newTestAccount(startingBalance);

const ctcAlice = alicezAccount.contract(backend);
const ctcBob = bobzAccount.contract(backend, ctcAlice.getInfo());

await Promise.all([
    ctcAlice.p.Alice({
        // implement Alice's interact object here
    }),
    ctcBob.p.Bob({
        // implement Bob's interact object here
    }),
]);