clear;
clc;
close all force;
close all;
app=NaN(1);  %%%%%%%%%This is to allow for Matlab Application integration.
format shortG
top_start_clock=clock;
folder1='C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\7GHz P2P Single Entry';
cd(folder1)
addpath(folder1)
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\Basic_Functions')
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\General_Terrestrial_Pathloss')
addpath('C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\General_Movelist')
addpath('C:\Local Matlab Data\Local MAT Data') %%%%%%%One Drive Error with mat files
pause(0.1)


'Fixed P2P Adjacent'

%%%%%%%%%%%%%%%%Example Code with OOBE and FDR
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Inputs
% rev=30
% rx_label='Channel A10'
% rx_freq_mhz=7435; %%%%%%%MHz 7420-7450MHz
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Inputs
rev=31
rx_label='Channel A1'
rx_freq_mhz=7465; %%%%%%%MHz 7450-7480MHz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
label='P2P'
tx_bw_mhz=100; %%%%%%%% carrier bandwidth [MHz] [B]
tx_eirp_mhz=42.5  %%%%42.5dBm/MHz at 100th (0,0)  
center_freq=7350; %%%%%%%MHz % carrier center [MHz]
zero_freq=7400
FreqMHz=center_freq; %%%%%%%%MHz
edge1=center_freq+tx_bw_mhz/2;
oobeSeg = [edge1  edge1+20   -13  ;     % band edge to 7420
           edge1+20  edge1+40   -30;    % 7420-7430 MHz
            edge1+30  Inf   -40  ];    % above 7430 MHz

cond_pwr_dBm=37.5;  % conducted power per transceiver [dBm], which is different than the 38.6dBm/1MHz or 58.6dBm/100MHz
tx_extrap_loss=-60; %%%%%%%%%TX Extrapolation Slope dB/Decade -60dB (Past the last point 7600Mhz)
%%%%%%% Rx IF Selectivity: p2p A10
array_rx_if=fliplr(horzcat(0,15,15.1,18,30,60,90,120,150,180,210)); %%%%Frequency MHz Half Bandwidth
array_rx_loss=fliplr(horzcat(0,0.1,15,30,70,110,150,190,230,270,310)); %%%%%%%dB Loss
rx_extrap_loss=-80; %%%%%%%%%RX Extrapolation Slope dB/Decade 60dB (This is generous)
%%%%%%%%%%%%%%%%%%%%%%%
rx_ant_heigt_m=30; %%%%%%meters
in_ratio=-10; %%%%%I/N Ratio
rx_nf=2;  %%%%%%%NF in dB
rx_ant_gain=37% %%%%%%Main Beam gain in dBi
phi_deg = 0:0.1:180;
D_m=1.8;  %%%%%%%%Just a placeholder
[G_dBi]=calc_antenna_f1245_rev1(app,phi_deg,rx_ant_gain,D_m,FreqMHz);

rx_bw_mhz=30; %%%%%Megahertz
rx_temp_k=293;%%%%%Noise Temperature K
x_pol_dB=2
radar_threshold=-138.7+10*log10(rx_bw_mhz)+10*log10(rx_temp_k)+in_ratio+x_pol_dB+-rx_ant_gain
guardband=abs(edge1-(rx_freq_mhz-rx_bw_mhz/2))
fdr_offset=abs(tx_bw_mhz/2+rx_bw_mhz/2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%Other Inputs
tx_height_m=30; %%%%%%2 meters
max_itm_dist_km=200;
reliability=50%
tf_clutter=0
tx_eirp=tx_eirp_mhz+10*log10(tx_bw_mhz/1) %%%%%%%71dBm/1Mhz
required_pathloss_fdr=ceil(tx_eirp-radar_threshold)
%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate the OOBE
[table_oobe]=calc_oobe_7ghz_rev1(app,rev,oobeSeg,tx_bw_mhz,center_freq,cond_pwr_dBm)
data_header_oobe=table_oobe.Properties.VariableNames;
cell_oobe_data=table2cell(table_oobe);
col_freq_offset_idx=find(matches(data_header_oobe,'offset_from_center_MHz'));
col_eirp_idx=find(matches(data_header_oobe,'EIRP_PSD_dBm_per_MHz'));
array_mask=cell2mat(cell_oobe_data(:,[col_freq_offset_idx,col_eirp_idx]));

%%%%%%%Normalize mask for FDR
norm_array_mask=array_mask;
norm_array_mask(:,2)=abs(array_mask(:,2)-max(array_mask(:,2)));
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%FDR Curves
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%FDR Inputs
array_tx_rf=fliplr(norm_array_mask(:,1)'); %%%%Frequency MHz (Base Station) [Half Bandwidth]
array_tx_mask=fliplr(norm_array_mask(:,2)'); %%%%%%%dB Loss
tx_freq_mhz=center_freq;
fdr_freq_separation=abs(tx_freq_mhz-rx_freq_mhz)
fdr_calc_mhz=ceil(fdr_freq_separation*1.25)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate FDR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Delta_Freq_Step=1
tic;
[FDR_dB,ED,VD,OTR,DeltaFreq,single_fdr_loss,trans_mask] = FDR_ModelII_vector_rev2(app,fdr_calc_mhz,array_tx_rf,array_rx_if,array_tx_mask,array_rx_loss,tx_extrap_loss,rx_extrap_loss,Delta_Freq_Step);
toc;


    figure;
    hold on;
    plot(VD(:,1)+rx_freq_mhz,VD(:,2),'-r')
    grid on;
    xlabel('Frequency [MHz]')
    ylabel('Normalized IF Mask [dB]')
    title(strcat('Receiver Selectivity:',rx_label))
    filename1=strcat('7GHz_Rx_',num2str(rx_freq_mhz),'_',num2str(rev),'.png');
    saveas(gcf,char(filename1))



    figure;
    hold on;
    plot(ED(:,1)+tx_freq_mhz,-1*ED(:,2)+tx_eirp_mhz,'-r')
    grid on;
    xlabel('Frequency [MHz]')
    ylabel('Emission Mask [dBm]')
    filename1=strcat('7GHz_Tx_',num2str(tx_freq_mhz),'_',num2str(rev),'.png');
    saveas(gcf,char(filename1))

zero_idx=nearestpoint_app(app,0,DeltaFreq);
array_fdr=horzcat(DeltaFreq(zero_idx:end)',FDR_dB(zero_idx:end));
fdr_idx=nearestpoint_app(app,fdr_freq_separation,array_fdr(:,1));
fdr_dB=array_fdr(fdr_idx,:);  %%%%%%Frequency, FDR Loss
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%FDR Plot
% figure;
% plot(FDR_dB)

fdr_freq=abs(rx_freq_mhz-center_freq)
figure;
hold on;
plot(array_fdr(:,1),array_fdr(:,2),'-b','LineWidth',2,'DisplayName','FDR Loss')
%xline(fdr_freq,'--r','LineWidth',3)
legend('Location','northwest')
title({strcat('FDR')})
grid on;
axis([0 250 0 100])
xlabel('Frequency Offset Between Center Frequencies [MHz]')
ylabel('FDR [dB]')
filename1=strcat('FDR_',num2str(rev),'.png');
saveas(gcf,char(filename1))

figure;
hold on;
plot(array_fdr(:,1),array_fdr(:,2),'-b','LineWidth',2,'DisplayName','FDR Loss')
xline(fdr_freq,'--r','LineWidth',3)
title({strcat('FDR')})
grid on;
axis([0 250 0 100])
xlabel('Frequency Offset Between Center Frequencies [MHz]')
ylabel('FDR [dB]')
filename1=strcat('FDR3_',num2str(rev),'.png');
saveas(gcf,char(filename1))

figure;
hold on;
plot(array_fdr(:,1)-fdr_offset,array_fdr(:,2),'-b','LineWidth',2,'DisplayName','FDR Loss')
xline(0,'--g','LineWidth',3)
xline(guardband,'-r','LineWidth',2)
legend('Location','northwest')
title({strcat('FDR: Example Rx and Base Station')})
grid on;
xlabel('Frequency Separation Between Edge Frequencies [MHz]')
ylabel('FDR [dB]')
xticks(-50:10:50)
axis([-50,50,0,100])
filename1=strcat('FDR2_',num2str(rev),'.png');
saveas(gcf,char(filename1))




%%%%%%%%%%Find the ITM Area Pathloss for the distance array
tic;
max_rx_height=rx_ant_heigt_m
[array_pathloss]=itm_area_dist_array_sea_rev2(app,reliability,tx_height_m,max_rx_height,max_itm_dist_km,FreqMHz);
toc;
tic;
save(strcat('Rev',num2str(rev),'_array_pathloss.mat'),'array_pathloss')
toc;


% figure;
% hold on;
% plot(array_pathloss(:,1),array_pathloss(:,2),'-g','LineWidth',3)
% xlabel('Distance [km]')
% ylabel('Pathloss [dB]')
% grid on;
% filename1=strcat('Pathloss_AdjacentMet_',num2str(rev),'.png');
% saveas(gcf,char(filename1))
% pause(0.1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
offset_freq=fdr_freq_separation
loss_vs_freq=array_fdr;
loss_vs_freq(:,2)=required_pathloss_fdr-array_fdr(:,2);

figure;
hold on;
plot(loss_vs_freq(:,1),loss_vs_freq(:,2),'-b')
grid on;



%%%%%%%%%%Find the Distance for each loss(:,2)
array_cross_idx=nearestpoint_app(app,loss_vs_freq(:,2),array_pathloss(:,2));
dist_vs_freq=array_pathloss(array_cross_idx,1);
dist_vs_freq(:,2)=loss_vs_freq(:,1);


cross_idx=nearestpoint_app(app,fdr_freq,dist_vs_freq(:,2))
dist_vs_freq(cross_idx,:)


figure;
hold on;
plot(dist_vs_freq(:,2),dist_vs_freq(:,1),'-b','LineWidth',2)
xline(fdr_freq,'--r','LineWidth',3)
xlabel('Frequency Separation [MHz]')
ylabel('Distance [km]')
xlim([50 120])
xticks(50:5:120)
grid on;
filename1=strcat('Dist_vs_Freq_',num2str(rx_freq_mhz),'_',num2str(rev),'.png');
saveas(gcf,char(filename1))



% % % figure;
% % % hold on;
% % % plot(dist_vs_freq(:,2)+tx_freq_mhz,dist_vs_freq(:,1),'-b','LineWidth',2)
% % % xline(zero_freq,'-r','LineWidth',2)
% % % xline(zero_freq+guardband,'-g','LineWidth',2)
% % % xlabel('Frequency [MHz]')
% % % ylabel('Distance [km]')
% % % %axis([7350 7780 0 100])
% % % grid on;
% % % filename1=strcat('Dist_vs_FreqMHZ_',num2str(rx_freq_mhz),'_',num2str(rev),'.png');
% % % saveas(gcf,char(filename1))





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end
%close all force;
cd(folder1)
'Done'

