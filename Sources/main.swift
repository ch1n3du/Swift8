// The Swift Programming Language
// https://docs.swift.org/swift-book

// Constants
let MEMORY_SIZE = 4096
let RESERVED_MEMORY_BYTES = 512 
let STACK_SIZE = 16

let SCREEN_WIDTH = 64
let SCREEN_HEIGTH = 32
let PIXEL_COUNT = SCREEN_WIDTH * SCREEN_WIDTH

let GENERAL_REGISTER_COUNT = 16

class Chip8 {
    var internal_display: [UInt8]

    var memory: [UInt8]
    var stack: [UInt16]

    var v_registers: [UInt8]
    var register_i: UInt16

    // Pseudo-registers
    var program_counter: UInt16
    var stack_pointer: UInt8

    // Timers
    var delay_timer: UInt8
    var sound_timer: UInt8

    init() {
        internal_display = Array.init(repeating: 0, count: PIXEL_COUNT)

        memory = Array.init(repeating: 0, count: MEMORY_SIZE)
        stack = Array.init(repeating: 0, count: STACK_SIZE)

        v_registers = Array.init(repeating: 0, count: GENERAL_REGISTER_COUNT)
        register_i = 0

        program_counter = 512
        stack_pointer = 0

        delay_timer = 0
        sound_timer = 0
    }

    func execute_timestep() throws {
        // Decrement the timers if they're non-negative
        if delay_timer > 0 {
            delay_timer -= 1
        }
        if sound_timer > 0 {
            sound_timer -= 1
        }
        try self.execute_current_instruction()
    }

    func execute_current_instruction() throws {
        // Read the instruction
        let byte_1 = self.memory[Int(program_counter)]
        let byte_2 = self.memory[Int(program_counter+1)]

        // Decode the instruction
        let (nibble_1, nibble_2) = byte_to_nibbles(byte: byte_1)
        let (nibble_3, nibble_4) = byte_to_nibbles(byte: byte_2)

        // Execute the instruction
        switch (nibble_1, nibble_2, nibble_3, nibble_4) {
            case (0, 0, 0xE, 0):
                self.clear_display_instruction()
            case (0, 0, 0xE, 0xE):
                try self.return_instruction()
            case (1, nibble_2, nibble_3, nibble_4):
                try self.jump_instruction(nibble_1: nibble_2, nibble_2: nibble_3, nibble_3: nibble_4)
            case (2, nibble_2, nibble_3, nibble_4):
                try self.call_instruction(nibble_1: nibble_2, nibble_2: nibble_3, nibble_3: nibble_4)
            default:
                self.print_debug_output(byte_1: byte_1, byte_2: byte_2)
        }
    }

    // Instructions

    // 00E0 - CLS
    func clear_display_instruction() {
        self.clear_internal_display()
        self.increment_program_counter()
    }

    // TODO: Test
    // 00EE - RET
    func return_instruction() throws {
        let address_at_stack_top = try self.pop_address_from_stack();
        program_counter = address_at_stack_top;
    }

    // TODO: Test
    // 1nnn - JP addr(nnn)
    func jump_instruction(nibble_1: UInt8, nibble_2: UInt8, nibble_3: UInt8) throws {
        let address_to_jump_to = nibbles_to_address(nibble_1: nibble_1, nibble_2: nibble_2, nibble_3: nibble_3)
        self.program_counter = address_to_jump_to
    }

    // TODO: Test
    // 2nnn - CALL addr
    func call_instruction(nibble_1: UInt8, nibble_2: UInt8, nibble_3: UInt8) throws {
        let address_of_subroutine_to_call = nibbles_to_address(nibble_1: nibble_1, nibble_2: nibble_2, nibble_3: nibble_3)
        try self.push_address_to_stack(address: self.program_counter)
        self.program_counter = address_of_subroutine_to_call
    }

    // 3xkk - SE Vx, byte
    func skip_next_if_byte_equal_instruction(index_x: UInt8, nibble_1: UInt8, nibble_2: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let byte = nibbles_to_byte(top: nibble_1, bottom: nibble_2)

        if value_at_register_x == byte {
            self.increment_program_counter()
        }
        self.increment_program_counter()
    }

    // 4xkk - SNE Vx, byte
    func skip_next_if_byte_not_equal_instruction(index_x: UInt8, nibble_1: UInt8, nibble_2: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let byte = nibbles_to_byte(top: nibble_1, bottom: nibble_2)

        if value_at_register_x != byte {
            self.increment_program_counter()
        }
        self.increment_program_counter()
    }

    // 5xy0 - SE Vx, Vy
    func skip_next_if_registers_equal_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        if value_at_register_x == value_at_register_y {
            self.increment_program_counter()
        }
        self.increment_program_counter()
    }

    // 6xkk - LD Vx, byte
    func load_byte_into_register_instruction(index_x: UInt8, nibble_1: UInt8, nibble_2: UInt8) {
        let byte = nibbles_to_byte(top: nibble_1, bottom: nibble_2)
        self.v_registers[Int(index_x)] = byte
        self.increment_program_counter()
    }

    // 7xkk - ADD Vx, byte
    func increment_register_by_byte_instruction(index_x: UInt8, nibble_1: UInt8, nibble_2: UInt8) {
        let byte = nibbles_to_byte(top: nibble_1, bottom: nibble_2)
        self.v_registers[Int(index_x)] += byte
        self.increment_program_counter()
    }

    // 8xy0 = LD Vx, Vy
    func load_register_y_into_register_y_instruction(index_x: UInt8, index_y: UInt8) {
        // let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        self.v_registers[Int(index_x)] = value_at_register_y
        self.increment_program_counter()
    }

    // 8xy1 = OR Vx, Vy
    func logical_or_register_x_and_y_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        self.v_registers[Int(index_x)] = value_at_register_x | value_at_register_y
        self.increment_program_counter()
    }

    // 8xy2 = AND Vx, Vy
    func logical_and_register_x_and_y_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        self.v_registers[Int(index_x)] = value_at_register_x & value_at_register_y
        self.increment_program_counter()
    }

    // 8xy3 = XOR Vx, Vy
    func logical_xor_register_x_and_y_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        self.v_registers[Int(index_x)] = value_at_register_x ^ value_at_register_y
        self.increment_program_counter()
    }

    // 8xy4 = ADD Vx, Vy
    func add_register_x_and_y_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        if Int(value_at_register_x) + Int(value_at_register_y) > 255 {
            self.v_registers[0xF] = 1
        } else {
            self.v_registers[0xF] = 0
        }

        self.v_registers[Int(index_x)] = UInt8(value_at_register_x.addingReportingOverflow(value_at_register_y).partialValue)
        self.increment_program_counter()
    }

    // 8xy5 = SUB Vx, Vy
    func subtract_register_x_and_y_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        if Int(value_at_register_x) > Int(value_at_register_y) {
            self.v_registers[0xF] = 1
        } else {
            self.v_registers[0xF] = 0
        }

        self.v_registers[Int(index_x)] = UInt8(value_at_register_x.subtractingReportingOverflow(value_at_register_y).partialValue)
        self.increment_program_counter()
    }

    // 8xy6 = SHR Vx {, Vy}
    func divide_register_x_by_2_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]

        if value_at_register_x % 2 == 1 {
            self.v_registers[0xF] = 1
        } else {
            self.v_registers[0xF] = 0
        }

        self.v_registers[Int(index_x)] = value_at_register_x / 2
        self.increment_program_counter()
    }

    // 8xy7 = SUBN Vx, Vy
    func subtractn_register_x_and_y_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        if Int(value_at_register_y) + Int(value_at_register_y) > 255 {
            self.v_registers[0xF] = 1
        } else {
            self.v_registers[0xF] = 0
        }

        self.v_registers[Int(index_x)] = UInt8(value_at_register_y.subtractingReportingOverflow(value_at_register_x).partialValue)
        self.increment_program_counter()
    }

    // 9xy0 - SE Vx, Vy
    func skip_next_if_registers_not_equal_instruction(index_x: UInt8, index_y: UInt8) {
        let value_at_register_x = self.v_registers[Int(index_x)]
        let value_at_register_y = self.v_registers[Int(index_y)]

        if value_at_register_x != value_at_register_y {
            self.increment_program_counter()
        }
        self.increment_program_counter()
    }

    // TODO: Test
    // Annn - LD I, addr
    func load_address_into_register_i(nibble_1: UInt8, nibble_2: UInt8, nibble_3: UInt8) throws {
        let address: UInt16 = nibbles_to_address(nibble_1: nibble_1, nibble_2: nibble_2, nibble_3: nibble_3)
        self.register_i = address
        self.increment_program_counter()
    }

    // Bnnn - JP V0, addr
    func load_address_into_register_v0(nibble_1: UInt8, nibble_2: UInt8, nibble_3: UInt8) throws {
        let address: UInt16 = nibbles_to_address(nibble_1: nibble_1, nibble_2: nibble_2, nibble_3: nibble_3)
        self.program_counter = address + UInt16(self.v_registers[0])
    }

    // Cxkk - RND Vx, byte
    func load_random_number_in_register_x_instruction(index_x: UInt8, nibble_1: UInt8, nibble_2: UInt8) {
        let byte = nibbles_to_byte(top: nibble_1, bottom: nibble_2)
        // TODO: Make actually random
        let random_number: UInt8 = 54

        self.v_registers[Int(index_x)] = random_number & byte
        self.increment_program_counter()
    }

    // Dxyn - DRW Vx, Vy, nibble(n)
    func draw_sprite_at_i_from_register_x_to_register_y_instruction(index_x: UInt8, index_y: UInt8, nibble: UInt8) {
        // TODO
    }

    // Ex9E - SKN Vx
    func skip_next_instruction_if_key_at_register_x_is_pressed_instruction(index_x: UInt8) {
        // TODO
    }

    // ExA1 - SKNP Vx
    func skip_next_instruction_if_key_at_register_x_is_not_pressed_instruction(index_x: UInt8) {
        // TODO
    }

    // Fx07 - LD Vx, DT
    func load_delay_timer_into_register_x_instruction(index_x: UInt8) {
        self.v_registers[Int(index_x)] = self.delay_timer
        self.increment_program_counter()
    }

    // Utility Methods

    func load_rom(rom_bytes: [UInt8]) throws {
        if rom_bytes.count > (4096 - RESERVED_MEMORY_BYTES) {
            throw Chip8Error.RomTooLarge(size: rom_bytes.count)
        }

        for (index, byte) in rom_bytes.enumerated() {
            memory[RESERVED_MEMORY_BYTES + index] = byte
        }
    }

    func clear_memory() {
        for i in 0...(MEMORY_SIZE-1) {
            memory[i] = 0
        }
    }

    func clear_internal_display() {
        for i in 0...(PIXEL_COUNT-1) {
            internal_display[i] = 0
        }
    }

    func clear_v_registers() {
        for i in 0...(GENERAL_REGISTER_COUNT-1) {
            v_registers[i] = 0
        }
    }

    func reset_emulator() {
        self.clear_internal_display()
        self.clear_memory()
        self.clear_v_registers()

        register_i = 0

        program_counter = 512
        stack_pointer = 0

        delay_timer = 0
        sound_timer = 0
    }

    func increment_program_counter() {
        program_counter += 2
    }

    func get_current_instruction() -> (UInt8, UInt8) {
        (self.memory[Int(self.program_counter)], self.memory[Int(self.program_counter)])
    }

    func pop_address_from_stack() throws -> UInt16 {
        if stack_pointer < 1 {
            throw Chip8Error.StackEmpty(program_counter: self.program_counter, instruction: self.get_current_instruction())
        }
        let address_at_stack_top: UInt16 = self.stack[Int(self.stack_pointer) - 1]
        stack_pointer -= 1

        return address_at_stack_top
    }

    func push_address_to_stack(address: UInt16) throws {
        if stack_pointer == 16 {
            throw Chip8Error.StackFull(program_counter: self.program_counter, instruction: self.get_current_instruction())
        }
        self.stack[Int(self.stack_pointer) - 1] = address
        self.stack_pointer += 1
    }

    func print_debug_output(byte_1: UInt8, byte_2: UInt8) {
        // Decode the instruction
        let (nibble_1, nibble_2) = byte_to_nibbles(byte: byte_1)
        let (nibble_3, nibble_4) = byte_to_nibbles(byte: byte_2)

        let nibbles_hex = "(\(byte_to_hex_string(nibble_1)), \(byte_to_hex_string(nibble_2)), \(byte_to_hex_string(nibble_3)), \(byte_to_hex_string(nibble_4)))"
        let bytes_hex = "(\(byte_to_hex_string(byte_1)), \(byte_to_hex_string(byte_2)))"

        print("\nEncountered Unimplemented Instruction \(nibbles_hex)")
        print("===================================================")
        print("| Current Instruction (Bytes)   | Raw(\(byte_1), \(byte_2))      Hex\(bytes_hex)")
        print("| Current Instruction (Nibbles) | Raw(\(nibble_1), \(nibble_2), \(nibble_3), \(nibble_4)) Hex\(nibbles_hex)")
        print("| Program Counter               | \(self.program_counter)")
        print("| Stack Pointer                 | \(self.stack_pointer)")
        print("| General Registers             | \(format_v_registers(registers:self.v_registers))")
    }
}

// ! VF register shouldn't be used


public enum Chip8Error: Error {
    case RomTooLarge(size: Int)
    case StackEmpty(program_counter: UInt16, instruction: (UInt8, UInt8))
    case StackFull(program_counter: UInt16, instruction: (UInt8, UInt8))

}

public func handleChip8Error(error: Chip8Error) {
    switch error {
        case .RomTooLarge(let size):
            print("ROM is '\(size)' bytes but interpreter only supports '\(MEMORY_SIZE - RESERVED_MEMORY_BYTES)' bytes maximum")
        case .StackEmpty(let program_counter, let instruction):
            print("")
        case .StackFull(let program_counter, let instruction):
            print("")
    }
}

let (byte_1_, byte_2_): (UInt8, UInt8) = (0x2A, 0xBC)
let (nibble_1_, nibble_2_) = byte_to_nibbles(byte: byte_1_)
let (nibble_3_, nibble_4_) = byte_to_nibbles(byte: byte_2_)

var test_chip8 = setup_chip8_and_execute_timestep(
    rom: nibbles_to_rom(nibble_1_, nibble_2_, nibble_3_, nibble_4_),
    preset_stack: nil,
    preset_display_pixels: nil, 
    preset_v_registers: nil,
    preset_register_i: nil,
    preset_delay_timer: nil,
    preset_sound_timer: nil
)

test_chip8.print_debug_output(byte_1: byte_1_, byte_2: byte_2_)