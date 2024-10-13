# Install MSIXBundle Certificate

To use the `.msixbundle` launcher some systems need to install the certificate
for it. The certificate is included in the launcher and can be accessed from
it's properties. The certificate needs to be installed in the `Trusted People`
certificate store on the local machine which requires administrator privileges.

## Step by step instructions

1. Open `.msixbundle` files __properties__
2. Select __Digital Signatures__ tab
3. Select signature named `nzbr`
4. Click __details__
5. Click __View Certificate__
6. Click __Install Certificate__
7. Select `Local Machine` and click __Next__
8. Select `Place all certificates in the following store` and click __Browse__
9. Select `Trusted People` from the list and click __OK__
10. Click __Next__ and then __Finish__

You should now be able to use the `.msixbundle` launcher.
