func nibbles_to_byte(top top_nibble: UInt8, bottom bottom_nibble: UInt8) -> UInt8 {
    // Assuming the top nibble and bottom nibble are: 
    // 0b00001010 and 0b00001111

    // 0b00000000
    var byte: UInt8 = 0
    // 0b00001010
    byte = byte | top_nibble
    // 0b10100000
    byte = byte << 4
    // 0b10101111
    byte = byte | bottom_nibble

    return byte
}


func byte_to_nibbles(byte: UInt8) -> (UInt8, UInt8) {
    let top_nibble = (byte >> 4) & 0b1111
    let bottom_nibble: UInt8 = (byte >> 0) & 0b1111
    
    return (top_nibble, bottom_nibble)
}

func byte_to_hex_string(_ byte: UInt8) -> String {
    "\(String(byte, radix: 16, uppercase: true))"
}

func nibbles_to_address(nibble_1: UInt8, nibble_2: UInt8, nibble_3: UInt8) -> UInt16{
    let nibble_1 = UInt16(nibble_1) & 0b1111
    let nibble_2 = UInt16(nibble_2) & 0b1111
    let nibble_3 = UInt16(nibble_3) & 0b1111

    var address: UInt16 = 0
    address = address        | UInt16(nibble_1)
    address = (address << 4) | UInt16(nibble_2)
    address = (address << 4) | UInt16(nibble_3)

    return address
}

func nibbles_to_rom(_ nibble_1: UInt8, _ nibble_2: UInt8, _ nibble_3: UInt8, _ nibble_4: UInt8) -> [UInt8] {
    [
        nibbles_to_byte(top: nibble_1, bottom: nibble_2),
        nibbles_to_byte(top: nibble_3, bottom: nibble_4),
    ]
}

func format_v_registers(registers: [UInt8]) -> String {
    var string = "V0=(\(registers[0]))"

    for x in 1...(GENERAL_REGISTER_COUNT-1) {
        string += " V\(byte_to_hex_string(UInt8(x)))=(\(registers[x]))"
    }

    return string
}

func pixel_coordinate_to_index(x: UInt, y: UInt) -> Int {
    if x > 63 {
        print("Invalid x-coordinate (\(x)) passed for pixel coordinate in 'pixel_coordinate_to_index'")
    }
    if y > 63 {
        print("Invalid y-coordinate (\(x)) passed for pixel coordinate in 'pixel_coordinate_to_index'")
    }

    return Int(((y-1) * 8) + x)
}

func setup_chip8_and_execute_timestep(
    rom: [UInt8],
    preset_stack: [UInt16]?,
    preset_display_pixels: [(UInt, UInt)]?,
    preset_v_registers: [UInt8: UInt8]?,
    preset_register_i: UInt16?,
    preset_delay_timer: UInt8?,
    preset_sound_timer: UInt8?
) -> Chip8 {
    // Setup
    let chippy = Chip8.init()

    if let preset_stack  {
        if preset_stack.count <= STACK_SIZE{
            for (index, address) in preset_stack.enumerated() {
                chippy.stack[index] = address
                chippy.stack_pointer += 1
            }
        }
    }

    if let preset_display_pixels {
        for (x, y) in preset_display_pixels {
            chippy.internal_display[pixel_coordinate_to_index(x: x, y: y)] = 1
        }
    }

    if let preset_v_registers {
        for (index, value) in preset_v_registers {
            if index < GENERAL_REGISTER_COUNT {
                chippy.v_registers[Int(index)] = value
            } else {
                print("Invalid index (\(byte_to_hex_string(index))) passed for V register in 'loadRomAndExecute'")
            }
        }
    }

    if let preset_register_i {
        chippy.register_i = preset_register_i
    }

    if let preset_delay_timer {
        chippy.delay_timer = preset_delay_timer
    }

    if let preset_sound_timer {
        chippy.sound_timer = preset_sound_timer
    }

    do {
        try chippy.load_rom(rom_bytes: rom)
        try chippy.execute_timestep()
    } catch let chip8_error as Chip8Error{
        handleChip8Error(error: chip8_error)
    } catch let _ {
        // print("Unknown Error: \(other_error)")
    }   


    return chippy
}
