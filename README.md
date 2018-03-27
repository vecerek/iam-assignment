# IAM Assignment 1

## API Description

The application is a dumb user management API which lets you to register, update, delete a user and list all users. A user is authorized to update and delete only himself. The authorization is implemented using JWT. The application itself is based on the framework Rails 5.

### Endpoints

| Method     | Endpoint   | Params                                 | Description                                                                                                                |
|------------|------------|----------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| POST       | /register  | email, password, password_confirmation | Creates a user account, returns the created user.                                                                          |
| POST       | /signin    | email, password                        | Signs in the user account, returns a JSON Web Token.                                                                       |
| GET        | /users/:id |                                        | Protected resource. Returns the user with the specified id.                                                                |
| PATCH, PUT | /users/:id | email, password, password_confirmation | Protected resource. Updates the details about the user with the specified id (only if the signed in user has the same id). |
| DELETE     | /users/:id |                                        | Protected resource. Deletes the user with the specified id (only if the signed in user has the same id).                   |
| GET        | /users     |                                        | Protected resource. Returns a list of registered users.                                                                    |

### JSON Web Token

The token is valid for 24 hours and is encoded using the `secret_key_base` to create a unique token. The payload contains the user ID. The user object is returned after each [API request authorization](https://github.com/vecerek/iam-assignment/blob/master/app/commands/authorize_api_request.rb#L9).
```ruby
def encode(payload, exp = 24.hours.from_now)
  payload[:exp] = exp.to_i
  JWT.encode(payload, Rails.application.secrets.secret_key_base)
end
```
**Notice:** The secret key base should not be exposed in an open source project, instead it should be read from the ENV variables. However, it is not that trivial to set up using Google App Engine - Google Compute/Kubernetes Engine provides more freedom by sacrificing the ease of deployment.

## Deployment

The API is deployed to Google App Engine and can be accessed through the domain https://iam.codekitchen.rocks/. The root does not serve any page, only the listed endpoints are available.

### Infrastructure components
The Ruby on Rails application is deployed to Google App Engine and uses MySQL 5.7 served by Google Cloud SQL. The deployment process is not further specified due to its complexity.

### Custom domain
To point a custom domain to the Google App Engine instance, it is required to create several A, AAAA records and a CNAME record to the IP addresses/domain provided by Google. In order to create an SSL certificate, it is necessary to verify the ownership of the domain. We decided to verify the domain through a DNS challenge instead of an HTTP one, thus it is necessary to point a custom domain we own to the deployed app.

| Record type | Data                  | Alias |
|-------------|-----------------------|-------|
| A           | 216.239.32.21         |       |
| A           | 216.239.34.21         |       |
| A           | 216.239.36.21         |       |
| A           | 216.239.38.21         |       |
| AAAA        | 2001:4860:4802:32::15 |       |
| AAAA        | 2001:4860:4802:34::15 |       |
| AAAA        | 2001:4860:4802:36::15 |       |
| AAAA        | 2001:4860:4802:38::15 |       |
| CNAME       | ghs.googlehosted.com  | iam   |

### SSL

The SSL certificate has been issued through [Let's Encrypt](https://letsencrypt.org/), the open Certificate Authority. SSL protects the client from man-in-the-middle attacks and thus e.g. from identity theft when registering an account or signing in.

Issuing a certificate is a straightforward process:

1. Install CertBot
```
$ brew install certbot
```

2. Verify your domain (e.g.: through a TXT DNS record)
```
$ sudo certbot certonly --manual --preferred-challenges dns
```
![Select domain for SSL](https://i.imgur.com/2EQq4XK.png)

3. Add a TXT record `_acme-challenge.iam.codekitchen.rocks` with the value returned by certbot.

![TXT DNS challenge](https://i.imgur.com/8X3Fvcb.png)

4. Wait and check for the record to be propagated.
```
$ dig -t txt _acme-challenge.iam.codekitchen.rocks
```

![Verify TXT DNS challenge](https://i.imgur.com/K8cu7xj.png)

5. Once it appears, proceed further with the Certbot terminal. If the domain is verified, a certificate and a private key should be returned.

![Certificate issued](https://i.imgur.com/QR9Rwoc.png)

6. Upload the certificate to Google Cloud Platforms. The private key must be converted into an RSA private key. The content of a private key is a base64 encoded Distinguished Encoding Rules (DER) encoding of ASN.1 used to represent keys. The RSA private key contains the information about the prime numbers used for the encryption and other integers such as `modulus`, `publicExponent`, `privateExponent`, etc.
```
$ sudo openssl rsa -inform pem -in /etc/letsencrypt/live/iam.codekitchen.rocks/privkey.pem -outform pem > /etc/letsencrypt/live/iam.codekitchen.rocks/rsaprivatekey.pem
```

![Convert private key](https://i.imgur.com/zxNpMwT.png)
![Upload certificate](https://i.imgur.com/jtbbhOJ.png)

7. Assign the SSL certificate to your domain in GCP.

![Assign SSL to domain](https://i.imgur.com/wfoIl77.png)
![Verify SSL assignement](https://i.imgur.com/hcKr6vg.png)

## Example Usage

1. Creating a user account
```
$ curl -H "Content-Type: application/json" -X POST -d '{"email":"test_user@student.aau.dk","password":"strong_pw","password_confirmation":"strong_pw"}' https://iam.codekitchen.rock/register
```
![Create account](https://i.imgur.com/krOZXjf.png)
![Try to create an account that already exists](https://i.imgur.com/owfz1aL.png)

2. Signing in
```
$ curl -H "Content-Type: application/json" -X POST -d '{"email":"test_user@student.aau.dk","password":"strong_pw"}' https://iam.codekitchen.rock/signin
```
![Signin](https://i.imgur.com/Ryj5rx4.png)

3. Accessing a protected resource without providing the authorization token
```
$ curl https://iam.codekitchen.rocks/users
```
![Accessing a protected resource without authorization](https://i.imgur.com/zRpYTOX.png)

4. Accessing a protected resource providing the authorization token
```
$ curl -H "Authorization: eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE1MjIyMDAzNjB9.OphWXL_lnxJt4YO30pf6D0-tM6HqC_4QIKMZHgQR3Ig" https://iam.codekitchen.rocks/users
```
![Accessing a protected resource with authorization](https://i.imgur.com/2sjYCn6.png)
