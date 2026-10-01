from faker import Faker

fake = Faker()

class FakeUser():
    @classmethod
    def get_data(cls):
        first_name = fake.first_name()
        last_name = fake.last_name()
        email = f"{first_name}_{last_name}@gmail.com"
        return [first_name,last_name,email]