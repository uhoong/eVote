// const { keccak256} = require('ethereumjs-util')
// const BN = require('bn.js')
// // s = '0x731377C1AAaEa2849bC55cDa03864B0065234223'
// // s = new BN(s.slice(2,s.length),16)
// // s = Buffer.from(BN('0x731377C1AAaEa2849bC55cDa03864B0065234223'))
// // s = Buffer.from([0x73,0x13,0x77,0xC1,0xAA,0xaE,0xa2,0x84,0x9b,0xC5,0x5c,0xDa,0x03,0x86,0x4B,0x00,0x65,0x23,0x42,0x23])

// console.log(keccak256(Buffer.from([1])))
// s = Buffer.alloc(32)
// console.log(s)
// s[s.length-1]=1
// console.log(s.toString('hex'))
// console.log(keccak256(s))
const { MerkleTree } = require('./helper/merkletree.js')
const abi = require('ethereumjs-abi');
const prover = require('./helper/prover.js')
const { keccak256} = require('ethereumjs-util')

data = prover.genTestData(42)
let tempComputationArray = [data[0].c]
computationArray = []
//compute the tally and add inputs to the circuit
for (let i = 1; i < data.length; i++)
    tempComputationArray.push(data[i].c.add(tempComputationArray[i - 1]))
for (let i = 0; i < tempComputationArray.length; i++)
    computationArray.push(abi.rawEncode(['uint[3]'], [[i, tempComputationArray[i].getX(), tempComputationArray[i].getY()]]))

computationMerkleTree = new MerkleTree(computationArray);
proof2 = computationMerkleTree.getHexProof(keccak256(computationArray[1]))
console.log(proof2)