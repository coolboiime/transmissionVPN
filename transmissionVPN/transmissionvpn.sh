# transmissionVPN
# ================

# VPN Settings
VPN_CONFID=l1234567890
VPN_CONFNAME=l2tpclient
VPN_PROTO=l2tp
VPN_UINAME=YourVPN

# VPN Optionals
VPN_TYPE=ppp
VPN_INTERFACE=ppp0
VPN_RETRY=10
VPN_INTERVAL=30

# VPN Features
PORT_FWD=
IP_CHECK=http://ipinfo.io/ip

# App Settings
TRANS_USER=sc-transmission
TRANS_GROUP=transmission
TRANS_VAR=/volume1/@appstore/transmission/var

# Script Starts
case "$1" in
start)
    # Checks if VPN is connected
    if echo `ifconfig` | grep -q "$VPN_TYPE"; then

        # Show Message
        echo "VPN is connected!"

    else

        # Show Message
        echo "VPN is connecting ..."

        # Reconnect VPN connection
        echo conf_id=$VPN_CONFID > /usr/syno/etc/synovpnclient/vpnc_connecting
        echo conf_name=$VPN_CONFNAME >> /usr/syno/etc/synovpnclient/vpnc_connecting
        echo proto=$VPN_PROTO >> /usr/syno/etc/synovpnclient/vpnc_connecting
        synovpnc reconnect --protocol=$VPN_PROTO --name=$VPN_UINAME --retry=$VPN_RETRY --interval=$VPN_INTERVAL

        # Checks if VPN is connected
        if echo `ifconfig` | grep -q "$VPN_TYPE"; then

            # Show Message
            echo "VPN is connected!"

            # Get VPN IP Address
            VPN_ADDR=`ifconfig $VPN_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'`
            echo "VPN Address is "$VPN_ADDR

            # Stops Transmission
            synopkg stop transmission

            # Binds IPv4 VPN Address to interface
            echo "Binding IPv4 VPN Address ..."
            cat $TRANS_VAR/settings.json | sed "s/.*bind-address-ipv4.*/    \"bind-address-ipv4\"\: \"$VPN_ADDR\",/g" > $TRANS_VAR/settings.json.bak
            chmod 600 $TRANS_VAR/settings.json.bak
            chown $TRANS_USER:$TRANS_GROUP $TRANS_VAR/settings.json.bak
            mv $TRANS_VAR/settings.json.bak $TRANS_VAR/settings.json

            # Starts Transmission
            synopkg start transmission

        else

            # Show Message
            echo "ERROR 1000: VPN cannot be connected."

        fi

    fi
;;
stop)
    # Checks if VPN is connected
    if echo `ifconfig` | grep -q "$VPN_TYPE"; then

        # Stops Transmission
        synopkg stop transmission

        # Binds IPv4 Home Address to interface
        echo "Binding IPv4 Home Address ..."
        cat $TRANS_VAR/settings.json | sed "s/.*bind-address-ipv4.*/    \"bind-address-ipv4\"\: \"127.0.0.1\",/g" > $TRANS_VAR/settings.json.bak
        chmod 600 $TRANS_VAR/settings.json.bak
        chown $TRANS_USER:$TRANS_GROUP $TRANS_VAR/settings.json.bak
        mv $TRANS_VAR/settings.json.bak $TRANS_VAR/settings.json

        # Starts Transmission
        synopkg start transmission

        # Show Message
        echo "VPN is disconnecting ..."

        # Kill VPN connection
        synovpnc kill_client

        if echo `ifconfig` | grep -q "$VPN_TYPE"; then

            # Show Message
            echo "ERROR 1001: VPN cannot be disconnected."

        else

            # Show Message
            echo "VPN is disconnected!"

        fi

    else

        # Show Message
        echo "VPN is disconnected!"

    fi
;;
repair)
    # Define variables
    VPN_ADDR=`ifconfig $VPN_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'`
    VPN_RESP=`curl -sS --interface $VPN_INTERFACE $IP_CHECK`
    VPN_PORT=`php -n portforward.php $VPN_ADDR $PORT_FWD`

    # Redefine variables if empty (bugfix)
    if [ "$VPN_ADDR" = "" ] || [ "$VPN_RESP" = "" ]; then
        VPN_ADDR="unknown"
        VPN_RESP="not found"
    fi

    # Display both IP addresses
    echo "Interface IP is "$VPN_ADDR
    echo "API Query IP is "$VPN_RESP
    echo "Network Port is "$VPN_PORT

    # If IP Address does not match or port is closed
    if [ "$VPN_ADDR" != "$VPN_RESP" ] || [ "$VPN_PORT" == "closed" ]; then

        # Show Message
        echo "VPN is not working ..."

        # Stops Transmission
        synopkg stop transmission

        # Binds IPv4 Home Address to interface
        echo "Binding IPv4 Home Address ..."
        cat $TRANS_VAR/settings.json | sed "s/.*bind-address-ipv4.*/    \"bind-address-ipv4\"\: \"127.0.0.1\",/g" > $TRANS_VAR/settings.json.bak
        chmod 600 $TRANS_VAR/settings.json.bak
        chown $TRANS_USER:$TRANS_GROUP $TRANS_VAR/settings.json.bak
        mv $TRANS_VAR/settings.json.bak $TRANS_VAR/settings.json

        # Checks if VPN is connected
        if echo `ifconfig` | grep -q "$VPN_TYPE"; then

            # Kill VPN connection
            synovpnc kill_client

        fi

        # Reconnect VPN connection
        echo conf_id=$VPN_CONFID > /usr/syno/etc/synovpnclient/vpnc_connecting
        echo conf_name=$VPN_CONFNAME >> /usr/syno/etc/synovpnclient/vpnc_connecting
        echo proto=$VPN_PROTO >> /usr/syno/etc/synovpnclient/vpnc_connecting
        synovpnc reconnect --protocol=$VPN_PROTO --name=$VPN_UINAME --retry=$VPN_RETRY --interval=$VPN_INTERVAL

        # Redefine variables
        VPN_ADDR=`ifconfig $VPN_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'`
        VPN_RESP=`curl -sS --interface $VPN_INTERFACE $IP_CHECK`

        # Redefine variables if empty (bugfix)
        if [ "$VPN_ADDR" = "" ] || [ "$VPN_RESP" = "" ]; then
            VPN_ADDR="unknown"
            VPN_RESP="not found"
        fi

        # Display both IP addresses
        echo "Interface IP is "$VPN_ADDR
        echo "API Query IP is "$VPN_RESP

        # Checks VPN connection
        if [ "$VPN_ADDR" != "$VPN_RESP" ]; then

            # Show Message
            echo "ERROR 1002: VPN cannot connect to the internet."

            # Kill VPN connection
            synovpnc kill_client

        else

            # Binds IPv4 VPN Address to interface
            echo "Binding IPv4 VPN Address ..."
            cat $TRANS_VAR/settings.json | sed "s/.*bind-address-ipv4.*/    \"bind-address-ipv4\"\: \"$VPN_ADDR\",/g" > $TRANS_VAR/settings.json.bak
            chmod 600 $TRANS_VAR/settings.json.bak
            chown $TRANS_USER:$TRANS_GROUP $TRANS_VAR/settings.json.bak
            mv $TRANS_VAR/settings.json.bak $TRANS_VAR/settings.json

        fi

        # Starts Transmission
        synopkg start transmission

    else

        # Show Message
        echo "VPN is already working!"

    fi
;;
install)
    # Show Message
    echo "Installing ..."

    # Stops Transmission
    synopkg stop transmission

    # Binds IPv4 Home Address to interface
    echo "Binding IPv4 Home Address ..."
    cat $TRANS_VAR/settings.json | sed "s/.*bind-address-ipv4.*/    \"bind-address-ipv4\"\: \"127.0.0.1\",/g" > $TRANS_VAR/settings.json.bak
    chmod 600 $TRANS_VAR/settings.json.bak
    chown $TRANS_USER:$TRANS_GROUP $TRANS_VAR/settings.json.bak
    mv $TRANS_VAR/settings.json.bak $TRANS_VAR/settings.json

    # Starts Transmission
    synopkg start transmission

    # Checks if VPN is connected
    if echo `ifconfig` | grep -q "$VPN_TYPE"; then

        # Kill VPN connection
        synovpnc kill_client

    fi

    # Show Message
    echo "Installed!"
;;
uninstall)
    # Show Message
    echo "Uninstalling ..."

    # Stops Transmission
    synopkg stop transmission

    # Binds IPv4 Default Address to interface
    echo "Binding IPv4 Default Address ..."
    cat $TRANS_VAR/settings.json | sed "s/.*bind-address-ipv4.*/    \"bind-address-ipv4\"\: \"0.0.0.0\",/g" > $TRANS_VAR/settings.json.bak
    chmod 600 $TRANS_VAR/settings.json.bak
    chown $TRANS_USER:$TRANS_GROUP $TRANS_VAR/settings.json.bak
    mv $TRANS_VAR/settings.json.bak $TRANS_VAR/settings.json

    # Starts Transmission
    synopkg start transmission

    # Checks if VPN is connected
    if echo `ifconfig` | grep -q "$VPN_TYPE"; then

        # Kill VPN connection
        synovpnc kill_client

    fi

    # Show Message
    echo "Uninstalled!"
;;
*)
    echo "Welcome to transmissionVPN!"
    echo "Usage: start|stop|repair|install|uninstall"
    echo "Example: sh transmissionvpn.sh start"
;;
esac

exit 0
