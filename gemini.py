#!/usr/bin/env python3
"""
Gemini CLI Client - A simple command line interface for Google's Gemini AI

Usage:
    ./gemini.py "Your question or prompt here"
    ./gemini.py -i (interactive mode)
    ./gemini.py -h (show help)
"""

import os
import sys
import argparse
import re
from pathlib import Path
import configparser
import google.generativeai as genai
from google.generativeai.types import HarmCategory, HarmBlockThreshold
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "gemini-cli"
CONFIG_FILE = CONFIG_DIR / "config.ini"
HISTORY_FILE = CONFIG_DIR / "history.txt"

# Model parameters
GEMINI_MODEL_TEXT = "gemini-2.0-flash"
GEMINI_MODEL_VISION = "gemini-2.0-flash"
GEMINI_TEMPERATURE = 0.5
GEMINI_MAX_OUTPUT_TOKENS = 2048
GEMINI_SAFETY_SETTINGS = {
    HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
    HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE,
    HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_NONE,
    HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_NONE
}

# ANSI color codes for terminal output
COLORS = {
    "reset": "\033[0m",
    "bold": "\033[1m",
    "code": "\033[38;5;246m",
    "code_bg": "\033[48;5;236m",
    "heading": "\033[1;38;5;75m",
    "list": "\033[38;5;220m"
}

def setup_config():
    """Create config directory and file if they don't exist"""
    if not CONFIG_DIR.exists():
        CONFIG_DIR.mkdir(parents=True)
    
    if not CONFIG_FILE.exists():
        config = configparser.ConfigParser()
        config["SETTINGS"] = {
            "model_text": GEMINI_MODEL_TEXT,
            "model_vision": GEMINI_MODEL_VISION,
            "temperature": str(GEMINI_TEMPERATURE),
            "max_output_tokens": str(GEMINI_MAX_OUTPUT_TOKENS),
            "max_output_lines": "0",  # 0 means no limit
            "use_colors": "true"      # Use ANSI colors in terminal output
        }
        
        with open(CONFIG_FILE, "w") as f:
            config.write(f)
        
        print(f"Config file created at {CONFIG_FILE}")
        print("Please ensure you have a .env file with GEMINI_API_KEY=your_api_key")
        sys.exit(1)

def load_config():
    """Load configuration from config file and environment"""
    config = configparser.ConfigParser()
    config.read(CONFIG_FILE)
    
    # Get API key from environment
    api_key = os.environ.get("GEMINI_API_KEY")
    
    if not api_key:
        print("Error: GEMINI_API_KEY not found in environment variables")
        print("Please create a .env file with GEMINI_API_KEY=your_api_key")
        sys.exit(1)
    
    model_text = config["SETTINGS"].get("model_text", GEMINI_MODEL_TEXT)
    model_vision = config["SETTINGS"].get("model_vision", GEMINI_MODEL_VISION)
    temperature = float(config["SETTINGS"].get("temperature", GEMINI_TEMPERATURE))
    max_output_tokens = int(config["SETTINGS"].get("max_output_tokens", GEMINI_MAX_OUTPUT_TOKENS))
    max_output_lines = int(config["SETTINGS"].get("max_output_lines", "0"))
    use_colors = config["SETTINGS"].getboolean("use_colors", True)
    
    return api_key, model_text, model_vision, temperature, max_output_tokens, max_output_lines, use_colors

def initialize_model(api_key, model_name, temperature, max_output_tokens):
    """Initialize the Gemini model"""
    genai.configure(api_key=api_key)
    
    generation_config = {
        "temperature": temperature,
        "max_output_tokens": max_output_tokens,
        "top_p": 0.95,
        "top_k": 64,
    }
    
    return genai.GenerativeModel(
        model_name,
        generation_config=generation_config,
        safety_settings=GEMINI_SAFETY_SETTINGS
    )

def format_markdown(text, use_colors=True):
    """Format markdown text with syntax highlighting for terminal"""
    if not use_colors:
        return text
    
    # Process code blocks
    def replace_code_block(match):
        lang = match.group(1).strip() if match.group(1) else ""
        code = match.group(2)
        
        # Format each line with code styling
        formatted_lines = []
        for line in code.split('\n'):
            formatted_lines.append(f"{COLORS['code']}{COLORS['code_bg']}{line}{COLORS['reset']}")
        
        return "\n".join([
            f"{COLORS['bold']}```{lang}{COLORS['reset']}",
            "\n".join(formatted_lines),
            f"{COLORS['bold']}```{COLORS['reset']}"
        ])
    
    # Handle code blocks with language specification
    text = re.sub(r'```([^\n]*)\n(.*?)\n```', replace_code_block, text, flags=re.DOTALL)
    
    # Handle headers
    text = re.sub(r'^(#+) (.*?)$', lambda m: f"{COLORS['heading']}{m.group(1)} {m.group(2)}{COLORS['reset']}", text, flags=re.MULTILINE)
    
    # Handle lists
    text = re.sub(r'^([ \t]*[-*]) (.*?)$', lambda m: f"{m.group(1)} {COLORS['list']}{m.group(2)}{COLORS['reset']}", text, flags=re.MULTILINE)
    
    return text

def save_to_history(prompt, response):
    """Save the prompt and response to history file"""
    with open(HISTORY_FILE, "a") as f:
        f.write(f"\n--- PROMPT ---\n{prompt}\n\n--- RESPONSE ---\n{response}\n\n")

def interact_with_model(model, prompt, max_output_lines, use_colors):
    """Send prompt to model and return formatted response"""
    try:
        response = model.generate_content(prompt)
        formatted_response = response.text
        
        # Limit output lines if specified
        if max_output_lines > 0:
            lines = formatted_response.split("\n")
            if len(lines) > max_output_lines:
                formatted_response = "\n".join(lines[:max_output_lines]) + "\n[Output truncated]"
        
        # Format markdown and apply syntax highlighting
        formatted_response = format_markdown(formatted_response, use_colors)
        
        save_to_history(prompt, response.text)  # Save original response to history
        return formatted_response
    except Exception as e:
        return f"Error: {str(e)}"

def interactive_mode(model, max_output_lines, use_colors):
    """Run in interactive mode with continuous prompting"""
    print(f"{COLORS['heading']}Gemini Interactive Mode (exit/quit/q to quit){COLORS['reset']}")
    try:
        while True:
            prompt = input(f"\n{COLORS['bold']}You:{COLORS['reset']} ")
            if prompt.lower() in ["exit", "quit", "q"]:
                break
            
            if not prompt.strip():
                continue
                
            print(f"\n{COLORS['bold']}Gemini:{COLORS['reset']}")
            response = interact_with_model(model, prompt, max_output_lines, use_colors)
            print(response)
    except KeyboardInterrupt:
        print("\nExiting...")

def main():
    parser = argparse.ArgumentParser(description="CLI client for Google's Gemini AI")
    parser.add_argument("prompt", nargs="?", help="The prompt to send to Gemini")
    parser.add_argument("-i", "--interactive", action="store_true", help="Interactive mode")
    parser.add_argument("--setup", action="store_true", help="Set up the config file")
    parser.add_argument("-v", "--vision", action="store_true", help="Use vision model for image analysis")
    parser.add_argument("--image", help="Path to image file for vision queries")
    parser.add_argument("--no-color", action="store_true", help="Disable colored output")
    
    args = parser.parse_args()
    
    if args.setup:
        setup_config()
        return
    
    # Ensure config is set up
    if not CONFIG_FILE.exists():
        setup_config()
    
    # Load config
    api_key, model_text, model_vision, temperature, max_output_tokens, max_output_lines, use_colors = load_config()
    
    # Override color setting if specified in command line
    if args.no_color:
        use_colors = False
    
    # Choose the appropriate model
    model_name = model_vision if args.vision else model_text
    
    # Initialize the model
    model = initialize_model(api_key, model_name, temperature, max_output_tokens)
    
    # Handle image input if provided
    if args.image:
        if not os.path.exists(args.image):
            print(f"Error: Image file not found: {args.image}")
            sys.exit(1)
        
        # Process image with prompt
        try:
            image_parts = [{"mime_type": "image/jpeg", "data": open(args.image, "rb").read()}]
            prompt_parts = []
            
            if args.prompt:
                prompt_parts = [args.prompt, image_parts[0]]
            else:
                prompt_parts = ["Describe this image in detail.", image_parts[0]]
            
            response = model.generate_content(prompt_parts)
            print(format_markdown(response.text, use_colors))
            return
        except Exception as e:
            print(f"Error processing image: {str(e)}")
            sys.exit(1)
    
    # Handle different modes
    if args.interactive:
        interactive_mode(model, max_output_lines, use_colors)
    elif args.prompt:
        response = interact_with_model(model, args.prompt, max_output_lines, use_colors)
        print(response)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
