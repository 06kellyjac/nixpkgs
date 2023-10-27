import ../make-test-python.nix ({ ... }: {
  name = "pam-pwquality";

  nodes.machine =
    { ... }:
    {
      security.pam.pwquality = {
        enable = true;

        settings = {
          minlen = 10;

          # require each class: lowercase uppercase digit and symbol/other
          minclass = 4;

          badwords = [ "foobar" "hunter42" "password" ];

          enforce_for_root = true;
        };
      };
    };

  testScript = ''
    import re

    # Helper functions

    def login_as_alice(pw):
      machine.wait_until_tty_matches(1, "login: ")
      machine.send_chars("alice\n")
      machine.wait_until_tty_matches(1, "Password: ")
      machine.send_chars(f"{pw}\n")
      machine.wait_until_tty_matches(1, "alice\@machine")


    def logout():
      machine.send_chars("logout\n")
      machine.wait_until_tty_matches(1, "login: ")

    machine.succeed("useradd -m alice")

    gen_pw_command = lambda pw: f"(echo '{pw}'; echo '{pw}') | passwd alice 2>&1"
    test_pw_succeed = lambda pw: machine.succeed(gen_pw_command(pw))
    test_pw_fail = lambda pw: machine.fail(gen_pw_command(pw))

    def expect_contains(cmdOut, expectedOut):
      assert (expectedOut in cmdOut), f"\nExpected:\n{expectedOut}\nWithin:\n{cmdOut}"


    # Consts

    pwquality_conf = "/etc/security/pwquality.conf"

    pw = "aB2$Nk4AW2"
    long_pw = "Nk4AW2wDkrXgcrNftdpKHpwqkRff7db@!96ubQCf-4H2q!d@9vP_EzAt@p*W*QqP"

    minlen = 10
    banned_words = [ "foobar", "hunter42", "password"]


    # Testing

    machine.wait_for_unit("multi-user.target")

    # print(f"pwquality.conf:\n{machine.succeed("cat /etc/security/pwquality.conf")}\n")
    print(machine.succeed("cat /etc/security/pwquality.conf"))


    with subtest("/etc/pam.d is configured as expected"):
      machine.succeed("egrep 'password requisite .*/lib/security/pam_pwquality.so' /etc/pam.d/ -R")


    with subtest(f"{pwquality_conf} is configured as expected"):
      machine.succeed(f"egrep '^minlen = 10$' {pwquality_conf}")
      machine.succeed(f"egrep '^enforce_for_root$' {pwquality_conf}")
      machine.succeed(f"egrep '^badwords = hunter42 password foobar$' {pwquality_conf}")


    with subtest("Test configuring passwords"):

      with subtest("Fail with complex but short password"):
        expect_contains(test_pw_fail(pw[:9]), "BAD PASSWORD: The password is shorter than 10 characters")


      with subtest("Fail with missing character type"):
        missing_class_error = "BAD PASSWORD: The password contains less than 4 character classes"

        with subtest("No lowercase"):
          expect_contains(test_pw_fail(pw.upper()), missing_class_error)

        with subtest("No uppercase"):
          expect_contains(test_pw_fail(pw.lower()), missing_class_error)

        with subtest("No digits"):
          expect_contains(test_pw_fail(re.sub("\d", "Z", pw)), missing_class_error)

        with subtest("No symbols"):
          expect_contains(test_pw_fail(pw.replace("$", "Z")), missing_class_error)


      with subtest("Fail with banned words"):
        banned_word_error = "BAD PASSWORD: The password contains forbidden words in some form"

        for banned_word in banned_words:
          expect_contains(test_pw_fail(pw + banned_word), banned_word_error)
          expect_contains(test_pw_fail(banned_word + pw), banned_word_error)
          expect_contains(test_pw_fail(pw[:5] + banned_word + pw[5:]), banned_word_error)


      with subtest("Pass with sufficient passwords"):
        password_change_success = "password updated successfully"

        expect_contains(test_pw_succeed(pw), password_change_success)
        login_as_alice(pw)
        logout()

        expect_contains(test_pw_succeed(long_pw), password_change_success)
        login_as_alice(long_pw)
        logout()

  '';
})
