I derive all my password from GPG smartcard (yubikey). But for untrusted device (or emergency access), I have a website to generate password by:

1. I type my reduced B key into browser.
2. Once my cursor / finger left the textbox, it immediately do a salted hash (so browser will not try to remember the password, which is catastrophic)
3. Salted hash will be transmitted to https server, which is hashed again, and did xor with a constant (you know why there's a xor? because... I changed algorithm but I don't want to change the underlying secret. So I did a xor to convert to old version)
4. Check the final secret. If it doesn't start with 'xx', return "Invalid Password".
5. Run the pswd generator with final secret, and password is shown.

It means: even if you type a wrong reduced B key, my website has 1% probablility show a password, just a wrong password. So attacker won't even know if his key is right.

--

Problem:

My B key is super super important. It's only used in most important scenario, and it's unacceptable to type on untrusted device even if it's reduced.
Please give me some idea to improve it, requirements:

1. B or reduced B is not typed into untrusted device directly.
2. If server got hacked, without client side information, pswdgen doesn't work.

(I know I can carry another secret string with me, and use it instead of reduced B. But, could I use my yubikey or some other hack?
I know I can do webauthn or something like that. But it would require server to store full secret. like `if auth passed, gen passwd`. I want secret to be split into two half, server hold some, client hold some)

--

Information: all my yubikey doesn't support HMAC-secret extension.
