from random import *
import os

class PasswordGenerator:
    dirname = os.path.dirname(__file__)
    filename = os.path.join(dirname, "passwords.txt")
    MIN_CHARACTERS = 12
    MAX_CHARACTERS = 30
    PASSWORD_COUNT = 3
    PASS = ""

    @classmethod
    def generate_passwords(cls, includes=[""]):
        # print(args[0])
        for _ in range(cls.PASSWORD_COUNT):
            characters = (
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$&%"
            )
            password = "".join(
                choice(characters)
                for _ in range(randint(cls.MIN_CHARACTERS, cls.MAX_CHARACTERS))
            )
            character_list = []
            [character_list.append(char) for char in password]
            print(len(character_list))

            for string in includes:
                character_list[randint(0, len(character_list) - 1)] = string

            modified_password = "".join(character_list)
            cls.PASS = modified_password

            with open(cls.filename, "a") as outfile:
                outfile.write(modified_password + "\n")
        return cls.PASS