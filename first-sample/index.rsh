'reach 0.1';

const Player = {
    getHand: Fun([], UInt),
    seeOutcome: Fun([UInt], Null),
};

const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player,
        wager: UInt,
    });
    const Bob = Participant('Bob', {
        ...Player,
        acceptWager: Fun([UInt], Null),
    });
    init();

    Alice.only(() => {
        const wager = declassify(interact.wager);
        const alicezHand = declassify(interact.getHand());
    });
    Alice.publish(wager, alicezHand).pay(wager);
    commit();

    //unknowable(Bob, Alice(alicezHand));  * this will cause error because alicezHand is already known to Bob*
    //so we can not enforce that at this step Bob shouldn't be knowing alicezHand
    Bob.only(() => {
        interact.acceptWager(wager);
        const bobzHand = declassify(interact.getHand());
    });
    Bob.publish(bobzHand).pay(wager);

    const outcome = (handAlice + (4 - bobzHand)) % 3;

    const [forAlice, forBob] = outcome == 2 ? [2, 0] : outcome == 0 ? [0, 2] : [1, 1];

    transfer(forAlice * wager).to(Alice);
    transfer(forBob * wager).to(Bob);

    commit();

    each([Alice, Bob], () => {
        interact.seeOutcome(outcome);
    });



});