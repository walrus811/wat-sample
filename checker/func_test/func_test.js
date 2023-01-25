fetch('./func_test.wasm')
.then(response=>response.arrayBuffer())
.then(bytes => WebAssembly.instantiate(bytes))
.then(results => {
  console.log("Loaded wasm module!");
  const instance = results.instance;
  console.log("instance", instance);

  const white = 2;
  const black = 1;
  const crownedWhite = 6;
  const crowendBlack = 5;

  console.log("Calling offset");
  const offset = instance.exports.offsetForPosition(3,4);
  console.log("Offset for 3,4 is ", offset);

  console.debug("White is white?", instance.exports.isWhite(white));
  console.debug("Black is black?", instance.exports.isBlack(black));
  console.debug("Black is white?", instance.exports.isWhite(black));
  console.debug("Uncrowned white",
  instance.exports.isWhite(instance.exports.withoutCrown(crownedWhite)));
  console.debug("Uncrowned black",
  instance.exports.isBlack(instance.exports.withoutCrown(crowendBlack)));
  console.debug("Crowned is crowned", instance.exports.isCrowned(crowendBlack));
  console.debug("Crowned is crowned (b)", instance.exports.isCrowned(crownedWhite));
});