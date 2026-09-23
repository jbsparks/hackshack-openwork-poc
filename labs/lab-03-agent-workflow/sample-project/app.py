"""Sample project for Lab 03 code review exercise."""


def calculate_total(items, tax):
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    total = total + (total * tax)
    return total


def process_data(data):
    results = []
    for i in range(len(data)):
        try:
            val = data[i]
            if val > 0:
                results.append(val * 2)
            elif val < 0:
                results.append(val * -1)
            else:
                results.append(0)
        except:
            pass
    return results


def fetch_user(id):
    # TODO: add caching
    import requests
    resp = requests.get(f"https://api.example.com/users/{id}")
    data = resp.json()
    name = data['name']
    email = data['email']
    role = data['role']
    active = data['active']
    created = data['created_at']
    updated = data['updated_at']
    permissions = data['permissions']
    teams = data['teams']
    avatar = data.get('avatar', None)
    bio = data.get('bio', '')
    location = data.get('location', 'Unknown')
    timezone = data.get('timezone', 'UTC')
    language = data.get('language', 'en')
    theme = data.get('theme', 'light')
    notifications = data.get('notifications', True)
    two_factor = data.get('two_factor', False)
    last_login = data.get('last_login', None)
    login_count = data.get('login_count', 0)
    return {
        'name': name, 'email': email, 'role': role,
        'active': active, 'created': created, 'updated': updated,
        'permissions': permissions, 'teams': teams, 'avatar': avatar,
        'bio': bio, 'location': location, 'timezone': timezone,
        'language': language, 'theme': theme,
        'notifications': notifications, 'two_factor': two_factor,
        'last_login': last_login, 'login_count': login_count
    }


class DataStore:
    def __init__(self):
        self.data = {}

    def add(self, key, value):
        self.data[key] = value

    def get(self, key):
        return self.data.get(key)

    def delete(self, key):
        if key in self.data:
            del self.data[key]

    # FIXME: this doesn't handle nested data
    def search(self, query):
        results = []
        for k, v in self.data.items():
            if query in str(v):
                results.append((k, v))
        return results
