By: Judrianne Mahigne

- Usage: -git-clone | -install-packages | -mysql | -rabbitmq | -apache2 | -ufw |-wireguard | -get

-- Example: ./1t490.sh -git-clone
             ./it490 -get mysql
             sudo ./it490.sh -install-packages
             sudo ./it490.sh -mysql

- To get server information:  -get (mysql | rabbitmq | apache | wireguard | ufw)

- If running from fresh Ubuntu (24 and above) install in the following order:

1. -install-packages
2. -git-clone (no sudo)
3. -mysql
4. -rabbitmq
5. -apache2
6. -wireguard
7. -ufw
