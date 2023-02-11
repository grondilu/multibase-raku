unit module Multibase;
use Base58;

our enum Encoding <
  identity
  base2
  base8
  base10
  base16
  base16upper
  base32
  base32upper
  base32hex
  base32hexupper
  base32pad
  base32padupper
  base32hexpad
  base32hexpadupper
  base32z
  base36
  base36upper
  base58flickr
  base58btc
  base64
  base64pad
  base64url
  base64urlpad
  base256emoji
>;

package Base256Emoji {
  our constant @alphabet = < 🚀 🪐 ☄ 🛰 🌌 🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘 🌍 🌏 🌎 🐉 ☀
    💻 🖥 💾 💿 😂 ❤ 😍 🤣 😊 🙏 💕 😭 😘 👍 😅 👏 😁 🔥 🥰 💔 💖 💙 😢 🤔 😆 🙄 💪
    😉 ☺ 👌 🤗 💜 😔 😎 😇 🌹 🤦 🎉 💞 ✌ ✨ 🤷 😱 😌 🌸 🙌 😋 💗 💚 😏 💛 🙂 💓 🤩
    😄 😀 🖤 😃 💯 🙈 👇 🎶 😒 🤭 ❣ 😜 💋 👀 😪 😑 💥 🙋 😞 😩 😡 🤪 👊 🥳 😥 🤤 👉
    💃 😳 ✋ 😚 😝 😴 🌟 😬 🙃 🍀 🌷 😻 😓 ⭐ ✅ 🥺 🌈 😈 🤘 💦 ✔ 😣 🏃 💐 ☹ 🎊 💘
    😠 ☝ 😕 🌺 🎂 🌻 😐 🖕 💝 🙊 😹 🗣 💫 💀 👑 🎵 🤞 😛 🔴 😤 🌼 😫 ⚽ 🤙 ☕ 🏆
    🤫 👈 😮 🙆 🍻 🍃 🐶 💁 😲 🌿 🧡 🎁 ⚡ 🌞 🎈 ❌ ✊ 👋 😰 🤨 😶 🤝 🚶 💰 🍓 💢
    🤟 🙁 🚨 💨 🤬 ✈ 🎀 🍺 🤓 😙 💟 🌱 😖 👶 🥴 ▶ ➡ ❓ 💎 💸 ⬇ 😨 🌚 🦋 😷 🕺 ⚠ 🙅
    😟 😵 👎 🤲 🤠 🤧 📌 🔵 💅 🧐 🐾 🍒 😗 🤑 🌊 🤯 🐷 ☎ 💧 😯 💆 👆 🎤 🙇 🍑 ❄ 🌴
    💣 🐸 💌 📍 🥀 🤢 👅 💡 💩 👐 📸 👻 🤐 🤮 🎼 🥵 🚩 🍎 🍊 👼 💍 📣 🥂 >;
}


our proto decode($ --> Blob) {*}
our proto encode(Blob, Encoding $) {*}
multi encode(Str $s, Encoding $encoding) { samewith $s.encode, $encoding }

multi encode($b, identity) { $b.new: 0, $b.list }
multi encode($b, base58btc) { 'z' ~ Base58::encode $b }
multi encode($b, base16upper) { 'F' ~ $b>>.fmt("%02X").join }
multi encode($b, base64pad)   {
  given run qw{basenc --base64}, :in, :out {
    .in.write: $b; .in.close;
    return 'M' ~ .out.slurp(:close).trim;
  }
}
multi encode($b, base64url)   {
  given run qw{basenc --base64url}, :in, :out {
    .in.write: $b; .in.close;
    return 'u' ~ .out.slurp(:close).trim.subst(/\=*$/,'');
  }
}
multi encode($b, base64url)   {
  given run qw{basenc --base64url}, :in, :out {
    .in.write: $b; .in.close;
    return 'u' ~ .out.slurp(:close).trim.subst(/\=*$/,'');
  }
}
multi encode($b, base32) { samewith($b, base32upper).lc }
multi encode($b, base32upper)   {
  given run qw{basenc --base32}, :in, :out {
    .in.write: $b; .in.close;
    return 'B' ~ .out.slurp(:close).trim.uc;
  }
}
multi encode($b, base32hexupper) { samewith($b, base32hex).uc }
multi encode($b, base32hex)   {
  given run qw{basenc --base32hex}, :in, :out {
    .in.write: $b; .in.close;
    return 'v' ~ .out.slurp(:close).trim.lc;
  }
}
multi encode(Blob $b, base256emoji) { '🚀' ~ @Base256Emoji::alphabet[@$b].join; }

multi decode(Blob $b where $b[0] == 0) { $b.subbuf: 1 }
multi decode(Str $ where /^^F(<[0..9A..F]>**2)+$$/) {
  blob8.new: $0.map: { :16(~$_) }
}
multi decode(Str $ where /^^B(<[A..Z2..7=]>+)$$/) {
  given run qw{base32 -d}, :in, :out, :bin {
    .in.write: $0.Str.encode;
    .in.close;
    return blob8.new: .out.slurp: :close;
  }
}
multi decode(Str $ where /^^z(<@Base58::alphabet>*)$$/) {
  Base58::decode $0.Str;
}
multi decode(Str $ where /^^M(<+alnum+[-_=]>+)$$/) {
  given run qw{basenc --base64url -d}, :in, :out, :bin {
    .in.write: $0.Str.encode;
    .in.close;
    return blob8.new: .out.slurp: :close;
  }
}
multi decode(Str  $ where /^^'🚀'/) {
  blob8.new: %(@Base256Emoji::alphabet.pairs.invert){$/.postmatch.comb};
}
