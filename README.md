# Acronyms REST API

Acronyms saving and sharing REST API made with Vapor. API has ability to: 
- CRUD on Acronyms (authenticated and non authenticated routes)
- CRUD on Categories (authenticated and non authenticated routes)
- CRUD on Users (authenitcated)
- Authentication with oAuth (Github, Google, Apple) and with username/password

## How to run: 

Before you start the server you will need to run Make command, to create containers for databases (testing and non testing one). It is spinned up using Docker so if you don't have it, install it :)

```bash
make reset_all
```

This can be also useful when you want to reset one of the databases or both, more in the `Makefile`.
Now you are nearly ready to start the server. All that is needed is `.env` file and this properies in it: 

```bash
GOOGLE_CALLBACK_URL= #google oAuth callback 
GOOGLE_CLIENT_ID= #google oAuth client id
GOOGLE_CLIENT_SECRET= #google oAuth client secret
GITHUB_CALLBACK_URL= #github oAuth callback
GITHUB_CLIENT_ID= #github oAuth client id
GITHUB_CLIENT_SECRET= #github oAuth client secret
IOS_APPLICATION_IDENTIFIER= #iOS app bundle identifier (for SingIn with Apple)
SENDGRID_API_KEY= #sendgrid api key for email sending :)
```

And now you are ready to start the party! 🥳 Now run:

```bash
swift run
```



