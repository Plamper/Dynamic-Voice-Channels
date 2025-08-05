import os
from bot import client

def main():
    TOKEN = os.environ.get("TOKEN")
    if not TOKEN:
        raise ValueError("TOKEN environment variable is required")
    
    bot = client.Bot()
    bot.run(TOKEN)

if __name__ == '__main__':
    main()