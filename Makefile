ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always

floppy_image: $(BUILD_DIR)/floppy.img

$(BUILD_DIR)/floppy.img: bootloader kernel
	@echo "Creating floppy image..."
	@dd if=/dev/zero of=$(BUILD_DIR)/floppy.img bs=512 count=2880
	@mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/floppy.img
	@dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/floppy.img bs=512 count=1 conv=notrunc
	@mcopy -i $(BUILD_DIR)/floppy.img $(BUILD_DIR)/kernel.bin ::

bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	@echo "Building bootloader..."
	@$(ASM) $(SRC_DIR)/bootloader/stage1/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	@echo "Building kernel..."
	@$(ASM) $(SRC_DIR)/kernel/kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

always:
	@mkdir -p $(BUILD_DIR)


clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)