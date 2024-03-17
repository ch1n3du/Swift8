import XCTest
@testable import Swift8

final class Swift8Tests: XCTestCase {
    func testNibbleToByteConversions() {
        let original_byte: UInt8 = 0b10101111
        let (top_nibble, bottom_nibble) = byte_to_nibbles(byte: original_byte)

        XCTAssertEqual(top_nibble, 0b00001010)
        XCTAssertEqual(bottom_nibble, 0b00001111)

        // let new_byte = nibbles_to_uint8(top_nibble: top_nibble, bottom_nibble: bottom_nibble)
        let new_byte = nibbles_to_byte(top: top_nibble, bottom: bottom_nibble)
        XCTAssertEqual(original_byte, new_byte)
    }

    func test_clear_display_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            rom: nibbles_to_rom(0, 0, 0xE, 0),

            preset_stack: nil, 
            preset_display_pixels: [
                (1, 23), (2, 24), (3, 25)
            ], 
            preset_v_registers: nil,
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        // Assert
        for pixel in chipper.internal_display {
            XCTAssertEqual(pixel, 0)
        }
    }

    func test_return_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            rom: nibbles_to_rom(0, 0, 0xE, 0xE),
            preset_stack: [0x1010], 
            preset_display_pixels: nil,
            preset_v_registers: nil,
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )


        // Assert
        XCTAssertEqual(chipper.program_counter, 0x1010)
    }

    func test_jump_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // JP addr(0xABC)
            rom: nibbles_to_rom(1, 0xA, 0xB, 0xC),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: nil,
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        // Assert
        XCTAssertEqual(chipper.program_counter, 0xABC)
    }

    func test_call_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 2nnn - CALL addr(0xnnn)
            rom: nibbles_to_rom(2, 0xA, 0xB, 0xC),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: nil,
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.program_counter, 0xABC)
        // Previous program counter should be 0
        XCTAssertEqual(chipper.stack[0], 0)
    }

    func test_skip_next_instruction_if_byte_equal_register_x_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 3xkk - SE Vx, byte(kk)
            rom: nibbles_to_rom(3, 0x7, 0xA, 0xB),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 0xAB],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.program_counter , 0x4)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_skip_next_instruction_if_byte_not_equal_register_x_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 4xkk - SNE Vx, byte(kk)
            rom: nibbles_to_rom(0x4, 0x7, 0xA, 0xB),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 0xAC],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.program_counter , 0x4)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_skip_next_instruction_if_register_x_equals_register_y_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 5xy0 - SE Vx, Vy
            rom: nibbles_to_rom(0x5, 0x7, 0x8, 0x0),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 0xAB, 0x8: 0xAB],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.program_counter , 0x4)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_load_byte_into_register_x_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 6xkk - LD Vx, byte(kk)
            rom: nibbles_to_rom(0x6, 0x7, 0xA, 0xB),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 0xAC],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.v_registers[7], 0xAB)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_increment_register_x_by_byte_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 7xkk - ADD Vx, byte(kk)
            rom: nibbles_to_rom(0x7, 0x7, 0x0, 0xB),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 0xA0],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.v_registers[7], 0xAB)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_load_register_y_into_register_x_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy0 - LD Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xB, 0x0),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x3, 0xB: 0x8,],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x8)
        XCTAssertEqual(chipper.v_registers[0xB], 0x8)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_logical_or_register_x_and_register_y_instuction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy1 - OR Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x1),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x4, 0xC: 0x9],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x4 | 0x9)
        XCTAssertEqual(chipper.v_registers[0xC], 0x9)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_logical_and_register_x_and_register_y_instuction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy2 - AND Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x2),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x4, 0xC: 0x9],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x4 & 0x9)
        XCTAssertEqual(chipper.v_registers[0xC], 0x9)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_logical_xor_register_x_and_register_y_instuction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy3 - XOR Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x3),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x4, 0xC: 0x9],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x4 ^ 0x9)
        XCTAssertEqual(chipper.v_registers[0xC], 0x9)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_add_register_x_and_register_y_instuction_nocarry() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy4 - ADD Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x4),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x1, 0xC: 0x5],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x1 + 0x5)
        XCTAssertEqual(chipper.v_registers[0xC], 0x5)
        XCTAssertEqual(chipper.v_registers[0xF], 0x0)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }


    func test_add_register_x_and_register_y_instuction_carry() {
        // Setup and execute
        // let chipper = setup_chip8_and_execute_timestep(
        //     // 8xy4 - ADD Vx, Vy
        //     rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x4),

        //     preset_stack: nil, 
        //     preset_display_pixels: nil,
        //     preset_v_registers: [0xA: 255, 0xC: 0x5],
        //     preset_register_i: nil,
        //     preset_delay_timer: nil,
        //     preset_sound_timer: nil
        // )   
        let chipper = Chip8.init()

        XCTAssertEqual(1, 1)
        XCTAssertEqual(chipper.v_registers[0xA], 0x5)
        // XCTAssertEqual(chipper.v_registers[0xC], 0x5)
        // XCTAssertEqual(chipper.v_registers[0xF], 0x1)
        // XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_subtract_register_x_and_register_y_instuction_notborrow() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy5 - SUB Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x5),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 200, 0xC: 0x9],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 200 - 0x9)
        XCTAssertEqual(chipper.v_registers[0xC], 0x9)
        XCTAssertEqual(chipper.v_registers[0xF], 0x1)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_subtract_register_x_and_register_y_instuction_borrow() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy5 - SUB Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x5),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x9, 0xC: 200],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], UInt8(0x9.subtractingReportingOverflow(200).partialValue))
        XCTAssertEqual(chipper.v_registers[0xC], 0x9)
        XCTAssertEqual(chipper.v_registers[0xF], 0x0)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_shr_instruction_odd() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy6 - SHR Vx {, Vy}
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x6),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x5],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x2)
        XCTAssertEqual(chipper.v_registers[0xF], 0x1)

        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_shr_instruction_even() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy6 - SHR Vx {, Vy}
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x6),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x6],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x3)
        XCTAssertEqual(chipper.v_registers[0xF], 0x0)

        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_subtractn_register_x_and_register_y_instuction_notborrow() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy7 - SUB Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x7),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 0x9, 0xC: 200],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], UInt8(200.subtractingReportingOverflow(0x9).partialValue))
        XCTAssertEqual(chipper.v_registers[0xC], 200)
        XCTAssertEqual(chipper.v_registers[0xF], 0x1)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_subtractn_register_x_and_register_y_instuction_borrow() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 8xy7 - SUBN Vx, Vy
            rom: nibbles_to_rom(0x8, 0xA, 0xC, 0x7),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0xA: 200, 0xC: 0x9],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], UInt8(0x9.subtractingReportingOverflow(200).partialValue))
        XCTAssertEqual(chipper.v_registers[0xC], 0x9)
        XCTAssertEqual(chipper.v_registers[0xF], 0x0)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_skip_next_instruction_if_register_x_not_equal_register_y_instruction_true() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 9xy0 - SNE Vx, Vy
            rom: nibbles_to_rom(0x9, 0x7, 0x8, 0x0),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 0xAB, 0x8: 0xAC],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.program_counter, 0x4)
    }

    func test_skip_next_instruction_if_register_x_not_equal_register_y_instruction_false() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // 9xy0 - SNE Vx, Vy
            rom: nibbles_to_rom(0x9, 0x7, 0x8, 0x0),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 0xAB, 0x8: 0xAB],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )

        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_load_address_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // Annn - LD I, addr(nnn)
            rom: nibbles_to_rom(0xA, 0xA, 0xB, 0xC),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: nil,
            preset_register_i: 0x7,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.register_i, 0xABC)
        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_jump_to_byte_plus_v0() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // Bnnn - JP V0, addr(nnn)
            rom: nibbles_to_rom(0xB, 0xA, 0xB, 0xC),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x0: 7],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.program_counter, 0xABC + 7)
    }

    func test_load_random_number_into_register_x_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            //  -
            rom: nibbles_to_rom(0xC, 0x7, 0xA, 0xB),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 23],
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertNotEqual(chipper.v_registers[0x7], 23)

        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_draw_sprite_at_i_from_register_x_to_register_y_instruction() {
        // Dxyn - DRW Vx, Vy, nibble(n)
        // TODO
    }

    func test_skip_next_instruction_if_key_at_register_x_is_pressed_instruction() {
        // TODO
        // Ex9E - SKN Vx
    }

    func test_skip_next_instruction_if_key_at_register_x_is_not_pressed_instruction() {
        // TODO
        // ExA1 - SKNP Vx
    }

    func test_load_sound_timer_into_register_x_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            // Fx07 - LD Vx, DT
            rom: nibbles_to_rom(0xF, 0x7, 0x0, 0x7),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: [0x7: 31],
            preset_register_i: nil, 
            preset_delay_timer: nil, 
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x4)
        XCTAssertEqual(chipper.v_registers[0xB], 0x4)

        XCTAssertEqual(chipper.program_counter, 0x2)
    }

    func test_instruction() {
        // Setup and execute
        let chipper = setup_chip8_and_execute_timestep(
            //  -
            rom: nibbles_to_rom(0x0, 0x0, 0x0, 0x0),

            preset_stack: nil, 
            preset_display_pixels: nil,
            preset_v_registers: nil,
            preset_register_i: nil,
            preset_delay_timer: nil,
            preset_sound_timer: nil
        )   

        XCTAssertEqual(chipper.v_registers[0xA], 0x4)
        XCTAssertEqual(chipper.v_registers[0xB], 0x4)

        XCTAssertEqual(chipper.program_counter, 0x2)
    }
}
