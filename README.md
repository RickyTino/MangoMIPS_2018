# MangoMIPS  
使用verilog HDL语言编写的轻量级CPU软核，为参加NSCSCC 2018所编写。代码的结构参考了雷思磊的OpenMIPS，并有一些细微改动。

## 指令集
遵循NSCSCC大赛指定的指令集架构（57）条，以及少量MIPS32r1中的指令，总共67条，列举如下：

#### 算术与逻辑指令： 
- ADDI, ADDIU, SLTI, SLTIU, ANDI, ORI, XORI, LUI;
- ADD, ADDU, SUB, SUBU, AND, OR, XOR, NOR, SLT, SLTU;
- SLL, SRL, SRA, SLLV, SRLV, SRAV;
- MUL, MULT, MULTU, DIV, DIVU;
- MADD, MADDU, MSUB, MSUBU;
- CLO, CLZ.

#### 移动指令：
- MOVZ, MOVN, MFHI, MTHI, MFLO, MTLO.

#### 跳转与分支指令：
- J, JAL, JR, JALR;
- BEQ, BNE, BGTZ, BLEZ;
- BGEZ, BGEZAL, BLTZ, BLTZAL;  

#### 加载与存储指令：
- LB, LBU, LH, LHU, LW;
- SB, SH, SW;
- LWL, LWR, SWL, SWR.

#### 空指令：
- NOP, SYNC, PREF.

#### 特权指令
- SYSCALL, BREAK, ERET.

## 架构 
- 采用单发射、顺序执行的经典五级流水架构；
- 使用数据转发解决除Load相关之外的数据相关；
- Load相关暂停流水线一拍;
- 实现了分支延迟槽，无分支预测。

## 特权资源
- 实现了以下7种例外：中断例外、系统调用例外、断点例外、保留指令例外、溢出、地址错例外、例外返回。
- 6位硬中断，2位软中断，均可屏蔽；
- 例外跳转地址统一为0xBFC0_0380。

## 地址空间及缓存

#### 地址空间
- 无TLB，虚拟地址通过硬连线映射到物理地址；
- kseg0、kseg1均映射至物理地址0x00000000至0x1FFFFFFF；
- 其余段直接用虚拟地址作为物理地址。

#### 数据Cache (DCache) 
- 大小16KB；
- Cache行大小64B；
- 映射方式：直接映射（1路）；
- 写策略：写回、按写分配；
- 数据接口支持Uncached访存；
- 对用户不可见。

#### 指令Cache (ICache)
- 大小16KB；
- Cache行大小64B；
- 映射方式：直接映射（1路）；
- 不支持写，不支持Uncached访存；
- 对用户不可见。

## 关于开源的一些说明
对于四个发布分支说明如下：
- master分支：包含其他分支的所有文件，可用于再开发；
- AXI_Cached：AXI接口版本，含Cache，同时也是哈工大威海1队参加NSCSCC2018龙芯杯的最终提交版本；
- SRAM_Interface：SRAM接口版本（SRAM接口时序参照Block Ram IP）
- SRAM_no_IP：无Xilinx IP核的SRAM接口版本，将原本以IP核实现的除法模块替换为普通的除法模块DIV，可用于其他FPGA平台如Altera。

由于新的重构版本MangoMIPS即将推出，除有重大BUG出现，否则不再对该版本进行更新。  
以此CPU纪念我第一次参加“龙芯杯”系统能力大赛。
