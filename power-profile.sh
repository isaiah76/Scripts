#!/bin/bash

# TLP configuration file location
TLP_CONF="/etc/tlp.conf"
TLP_BACKUP="/etc/tlp.conf.backup"

# Check for required dependencies
check_dependencies() {
    for cmd in ryzenadj tlp-stat; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it first."
            echo "For ryzenadj: 'yay -S ryzenadj'"
            echo "For TLP: 'sudo pacman -S tlp'"
            exit 1
        fi
    done
}

# Check if running as root/sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script with sudo privileges."
        exit 1
    fi
}

# Create a backup of TLP configuration if needed
backup_tlp_conf() {
    if [ ! -f "$TLP_BACKUP" ]; then
        echo "Creating backup of TLP configuration at $TLP_BACKUP"
        cp "$TLP_CONF" "$TLP_BACKUP"
    fi
}

# Apply TLP settings based on profile
configure_tlp() {
    backup_tlp_conf
    
    case $1 in
        "battery")
            echo "Configuring TLP for battery optimization..."
            sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="powersave"/' "$TLP_CONF"
            sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT="powersave"/' "$TLP_CONF"
            sed -i 's/^#\?CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=0/' "$TLP_CONF"
            sed -i 's/^#\?CPU_BOOST_ON_BAT=.*/CPU_BOOST_ON_BAT=0/' "$TLP_CONF"
            sed -i 's/^#\?ENERGY_PERF_POLICY_ON_AC=.*/ENERGY_PERF_POLICY_ON_AC=power/' "$TLP_CONF"
            sed -i 's/^#\?ENERGY_PERF_POLICY_ON_BAT=.*/ENERGY_PERF_POLICY_ON_BAT=power/' "$TLP_CONF"
            sed -i 's/^#\?PCIE_ASPM_ON_BAT=.*/PCIE_ASPM_ON_BAT=powersupersave/' "$TLP_CONF"
            ;;
            
        "balanced")
            echo "Configuring TLP for balanced operation..."
            sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="schedutil"/' "$TLP_CONF"
            sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT="schedutil"/' "$TLP_CONF"
            sed -i 's/^#\?CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=1/' "$TLP_CONF"
            sed -i 's/^#\?CPU_BOOST_ON_BAT=.*/CPU_BOOST_ON_BAT=0/' "$TLP_CONF"
            sed -i 's/^#\?ENERGY_PERF_POLICY_ON_AC=.*/ENERGY_PERF_POLICY_ON_AC=balance_performance/' "$TLP_CONF"
            sed -i 's/^#\?ENERGY_PERF_POLICY_ON_BAT=.*/ENERGY_PERF_POLICY_ON_BAT=balance_power/' "$TLP_CONF"
            sed -i 's/^#\?PCIE_ASPM_ON_BAT=.*/PCIE_ASPM_ON_BAT=default/' "$TLP_CONF"
            ;;
            
        "performance")
            echo "Configuring TLP for maximum performance..."
            sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="performance"/' "$TLP_CONF"
            sed -i 's/^#\?CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT="performance"/' "$TLP_CONF"
            sed -i 's/^#\?CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=1/' "$TLP_CONF"
            sed -i 's/^#\?CPU_BOOST_ON_BAT=.*/CPU_BOOST_ON_BAT=1/' "$TLP_CONF"
            sed -i 's/^#\?ENERGY_PERF_POLICY_ON_AC=.*/ENERGY_PERF_POLICY_ON_AC=performance/' "$TLP_CONF"
            sed -i 's/^#\?ENERGY_PERF_POLICY_ON_BAT=.*/ENERGY_PERF_POLICY_ON_BAT=performance/' "$TLP_CONF"
            sed -i 's/^#\?PCIE_ASPM_ON_BAT=.*/PCIE_ASPM_ON_BAT=performance/' "$TLP_CONF"
            ;;
    esac
    
    # Restart TLP service to apply changes
    systemctl restart tlp.service
    echo "TLP configuration updated and service restarted"
}

# Apply power profiles
apply_profile() {
    case $1 in
        "battery")
            echo "Applying battery saving profile..."
            ryzenadj --stapm-limit=8000 --fast-limit=10000 --slow-limit=8000
            configure_tlp "battery"
            echo "CPU power limited to 8W for better battery life"
            ;;
            
        "balanced")
            echo "Applying balanced profile..."
            ryzenadj --stapm-limit=15000 --fast-limit=18000 --slow-limit=15000
            configure_tlp "balanced"
            echo "CPU power set to balanced 15W mode"
            ;;
            
        "performance")
            echo "Applying performance profile..."
            ryzenadj --stapm-limit=20000 --fast-limit=25000 --slow-limit=20000
            configure_tlp "performance"
            echo "CPU power boosted to 20W for maximum performance"
            ;;
            
        "custom")
            if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
                echo "Custom profile requires 3 values: stapm-limit fast-limit slow-limit"
                echo "Example: $0 custom 12000 15000 12000"
                exit 1
            fi
            echo "Applying custom profile: stapm=$2mW, fast=$3mW, slow=$4mW"
            ryzenadj --stapm-limit=$2 --fast-limit=$3 --slow-limit=$4
            
            # Ask which TLP profile to use with custom TDP settings
            echo "Which TLP profile would you like to use with these custom TDP settings?"
            echo "1. Battery optimized"
            echo "2. Balanced"
            echo "3. Performance"
            echo "4. Keep current TLP settings"
            read -p "Enter choice [1-4]: " tlp_choice
            
            case $tlp_choice in
                1) configure_tlp "battery" ;;
                2) configure_tlp "balanced" ;;
                3) configure_tlp "performance" ;;
                4) echo "Keeping current TLP settings" ;;
                *) echo "Invalid choice, keeping current TLP settings" ;;
            esac
            
            echo "Custom CPU power profile applied"
            ;;
            
        *)
            show_usage
            ;;
    esac
}

# Restore original TLP configuration
restore_tlp_conf() {
    if [ -f "$TLP_BACKUP" ]; then
        echo "Restoring original TLP configuration..."
        cp "$TLP_BACKUP" "$TLP_CONF"
        systemctl restart tlp.service
        echo "Original TLP configuration restored"
    else
        echo "No TLP configuration backup found"
    fi
}

# Show current TDP and TLP settings
show_current_settings() {
    echo "Current TDP Settings:"
    ryzenadj -i | grep -E "STAPM|PPT"
    echo ""
    echo "Current TLP Status:"
    tlp-stat -s | head -n 10
    echo ""
    echo "CPU Frequency Scaling:"
    tlp-stat -p | grep -E "scaling_governor|boost|energy_perf"
}

# Show detailed TLP settings
show_detailed_tlp() {
    echo "Detailed TLP Configuration:"
    tlp-stat -c
}

# Show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo "Available commands:"
    echo "  battery      - Low power mode for better battery life (8W)"
    echo "  balanced     - Balanced mode for daily use (15W)"
    echo "  performance  - High performance mode (20W)"
    echo "  custom X Y Z - Custom TDP values (stapm-limit, fast-limit, slow-limit in mW)"
    echo "  status       - Show current TDP and TLP settings summary"
    echo "  tlp-details  - Show detailed TLP configuration"
    echo "  tlp-restore  - Restore original TLP configuration"
    echo "  help         - Show this help message"
}

# Main script
check_dependencies

case $1 in
    "battery"|"balanced"|"performance")
        check_sudo
        apply_profile $1
        ;;
    "custom")
        check_sudo
        apply_profile $1 $2 $3 $4
        ;;
    "status")
        show_current_settings
        ;;
    "tlp-details")
        show_detailed_tlp
        ;;
    "tlp-restore")
        check_sudo
        restore_tlp_conf
        ;;
    "help"|*)
        show_usage
        ;;
esac

# Save the last profile
if [[ "$1" != "status" && "$1" != "tlp-details" && "$1" != "tlp-restore" && "$1" != "help" && "$1" != "" ]]; then
    echo $@ > ~/.last_power_profile
    echo "Profile saved. Use '$0' without arguments to reapply last profile."
fi

exit 0
