#!/bin/bash

# Increase lockout limit to 10 and decrease timeout to 2 minutes
sudo sed -i 's|^\(auth\s\+required\s\+pam_faillock.so\)\s\+preauth.*$|\1 preauth silent deny=10 unlock_time=120|' "/etc/pam.d/system-auth"
sudo sed -i 's|^\(auth\s\+\[default=die\]\s\+pam_faillock.so\)\s\+authfail.*$|\1 authfail deny=10 unlock_time=120|' "/etc/pam.d/system-auth"

# Ensure lockout limit is reset on restart
sudo sed -i '/pam_faillock\.so preauth/d' /etc/pam.d/sddm-autologin
sudo sed -i '/auth.*pam_permit\.so/a auth        required    pam_faillock.so authsucc' /etc/pam.d/sddm-autologin

# Update or add faillock configuration while preserving comments
# Check if deny line exists (uncommented), update it; otherwise append it
if sudo grep -q '^[[:space:]]*deny[[:space:]]*=' /etc/security/faillock.conf; then
    sudo sed -i 's/^[[:space:]]*deny[[:space:]]*=.*/deny = 10/' /etc/security/faillock.conf
else
    echo "deny = 10" | sudo tee -a /etc/security/faillock.conf > /dev/null
fi

# Check if unlock_time line exists (uncommented), update it; otherwise append it
if sudo grep -q '^[[:space:]]*unlock_time[[:space:]]*=' /etc/security/faillock.conf; then
    sudo sed -i 's/^[[:space:]]*unlock_time[[:space:]]*=.*/unlock_time = 120/' /etc/security/faillock.conf
else
    echo "unlock_time = 120" | sudo tee -a /etc/security/faillock.conf > /dev/null
fi

# Check if silent line exists (uncommented), update it; otherwise append it
if sudo grep -q '^[[:space:]]*silent' /etc/security/faillock.conf; then
    : # silent already exists, do nothing
else
    echo "silent" | sudo tee -a /etc/security/faillock.conf > /dev/null
fi
