clear, clc
%-----Setting up universal variables---------------------------------------
server_running = 1; %Variable used to check if the server is running or not
timeout_counter = 0;%Variable used to check connection timeout
is_connected = 0;   %Variable used to check that we are still connected
xmax = 65;          %X Maximum Value 
xmin = 0;           %X Minimum Value
yminA = -3;         %Set Y-min acceleration value
ymaxA = 3;          %Set Y-max acceleration value
yminG = -250;       %Set Y-min gyroscope rotation value
ymaxG = 250;        %Set Y-max gyroscope rotation value
yminFlex = -20;    %Set Y-max for flex
ymaxFlex =  140;    %Set Y-min for flex
delay = .00;        %Delay between readings
time = 0;           %Variable to hold current time(Sample number)
count = 1;          %Counts the number of samples taken
dX1 = 0;            %X-axis value 1 -> Wrist X-acceleration
dY1 = 0;            %Y-axis value 1 -> Wrist Y-acceleration
dZ1 = 0;            %Z-axis value 1 -> Wrist Z-acceleration
dX2 = 0;            %X-axis value 2 -> Wrist X-rotation
dY2 = 0;            %Y-axis value 2 -> Wrist Y-rotation
dZ2 = 0;            %Z-axis value 2 -> Wrist Z-rotation
dX3 = 0;            %X-axis value 3 -> Shoulder X-rotation
dY3 = 0;            %Y-axis value 3 -> Shoulder Y-rotation
dZ3 = 0;            %Z-axis value 3 -> Shoulder Z-rotation
dFlex = 0;          %Flex reading value
xLabel = 'Sample Number';               % Universal x-label for all figures
yLabelA = 'Linear Acceleration (g)';    % y-axis label for accelerometer
yLabelG = 'Angular Rotation Dp(s)';     % y-axis label for gyroscopes   
yLabelFlex = 'Arm angle';
plotGrid = 'off'; 
%-----Variables for first figure-------------------------------------------
plotTitle1 = 'Lower Arm/Wrist Acceleration';  % plot title
legendwax = 'Vertical Axis Acceleration(Internal/External)';
legendway = 'Frontal  Axis Acceleration(Flexion/Extension)';
legendwaz = 'Sagital  Axis Acceleration(Abduction/Adduction)';
%----Variables for second figure-------------------------------------------
plotTitle2 = 'Lower Arm/Wrist Rotation';  % plot title
legendwgx = 'Vertical Axis Rotation(Internal/External)';
legendwgy = 'Frontal  Axis Rotation(Flexion/Extension)';
legendwgz = 'Sagital  Axis Rotation(Abduction/Adduction)';
%----Variables for third figure--------------------------------------------
plotTitle3 = 'Shoulder Rotation';  % plot title
legendsgx = 'Vertical Axis Rotation(Internal/External)';
legendsgy = 'Sagital Axis Rotation(Abduction/Adduction)';
legendsgz = 'Frontal Axis Rotation(Flexion/Extension)';
%----Variables for forth figure
plotTitle4 = 'Flex Reading';
legendFlex = 'Flex mapped angle value';
%---While loop that runs until the program (Server) is terminated----------
while server_running == 1
    %----Setting up first figure-----------------------------------------------
    f1 = figure; %Figure 1 is used to display wrist accelerometer values               
    %Set up Plot
    plotGraphwax = plot(time,dX1,'-r' );%every AnalogRead needs to be on its own Plotgraph
    hold on                             %hold on makes sure all of the channels are plotted
    plotGraphway = plot(time,dY1,'-b');
    plotGraphwaz = plot(time,dZ1,'-g' );
    title(plotTitle1,'FontSize',15);
    xlabel(xLabel,'FontSize',15);
    ylabel(yLabelA,'FontSize',15);
    legend(legendwax,legendway,legendwaz);
    xlim([xmin xmax]);
    ylim([yminA ymaxA]);
    grid(plotGrid); 
%----Setting up Second figure----------------------------------------------
    f2 = figure; %Figure 2 is used to display wrist gyroscope values
    %Set up Plot
    plotGraphwgx = plot(time,dX2,'-r' ); %every AnalogRead needs to be on its own Plotgraph
    hold on                              %hold on makes sure all of the channels are plotted
    plotGraphwgy = plot(time,dY2,'-b');
    plotGraphwgz = plot(time,dZ2,'-g' );
    title(plotTitle2,'FontSize',15);
    xlabel(xLabel,'FontSize',15);
    ylabel(yLabelG,'FontSize',15);
    legend(legendwgx,legendwgy,legendwgz);
    xlim([xmin xmax]);
    ylim([yminG ymaxG]);
    grid(plotGrid); 
    %----Setting up Third figure-----------------------------------------------
    f3 = figure; %Figure 3 is used to display Shoulder gyrscope values
    plotGraphsgx = plot(time,dX3,'-r' );%every AnalogRead needs to be on its own Plotgraph
    hold on                             %hold on makes sure all of the channels are plotted
    plotGraphsgy = plot(time,dY3,'-b');
    plotGraphsgz = plot(time,dZ3,'-g' );
    title(plotTitle3,'FontSize',15);
    xlabel(xLabel,'FontSize',15);
    ylabel(yLabelG,'FontSize',15);
    legend(legendsgx,legendsgy,legendsgz);
    xlim([xmin xmax]);
    ylim([yminG ymaxG]);
    grid(plotGrid); 
    %NOTE: NEW GRAPH CAN BE IMPLEMENTED  FOR FLEX VALUES!
    f4 = figure; %Figure 4 is used to display FLEX
    plotGraphFlex = plot(time,dFlex,'-r' );  
    title(plotTitle4,'FontSize',15);
    xlabel(xLabel,'FontSize',15);
    ylabel(yLabelFlex,'FontSize',15);
    legend(legendFlex);
    xlim([xmin xmax]);
    ylim([yminFlex ymaxFlex]);
    grid(plotGrid);
    %Create TCP object, with timeout limit of 10 seconds for replies
    t = tcpip('0.0.0.0',8000,'NetworkRole', 'server', 'Timeout', 10); %Tcp object port 8000
    fprintf('Waiting for connnection \n');
    fopen(t);%Wait for connection
    is_connected = 1;%Connection stablished, setting up figures 
    fprintf('Connection with client established \n');
    pause(0.5);%Wait for half a second
    while is_connected == 1 %While client is connected
       flushinput(t);%Flush buffer input
         while (count<xmax)%While our graph is within x-limits
          data = fscanf(t);
          disp(data);
          if contains(data,'end') == 1 %Close the application! 
           count = xmax + 2;
           is_connected = 0;
           server_running = 0;
          elseif contains(data,'pause') == 1 %Wait for new command
           timeout_counter = 0;
           pause(0.01);
           flushinput(t);
          elseif contains(data,'WA') == 1 %If we have data 
           timeout_counter = 0;
           %Split the data accordingly and then post-process it!
           wristA = extractBetween(data,'WA: (',')');%Wrist accel X,Y,Z readings
           wristG = extractBetween(data,'WG: (',')');%Wrist gyro X,Y,Z readings
           shoulderG = extractBetween(data,'SG: (',')');%Shoulder gyro X,Y,Z readings
           Flex = extractBetween(data,'FLEX: (',')');%Flex reading
           Flex = str2double(Flex);%Getting result as double
           rawFlex = Flex; %Saving raw value
           Flex = myMap(Flex,30,140,0,120); %Mapping Flex reading to an angle
           Flex = constrain(rawFlex,Flex,0,120); %Constraining our reading
           WA = split(wristA);%Split readings by spaces into array WA
           RawWAX = str2double(WA{1});
           RawWAY = str2double(WA{2});
           RawWAZ = str2double(WA{3});
           if RawWAX >= 32768
              RawWAX = RawWAX - 65536;
           end
           if RawWAY >= 32768
              RawWAY = RawWAY - 65536;
           end
           if RawWAZ >= 32768
              RawWAZ = RawWAZ - 65536;
           end
           %Applying standard datasheet calibration 
           WAX = ((RawWAX*0.061)/1000);
           WAY = ((RawWAY*0.061)/1000);
           WAZ = ((RawWAZ*0.061)/1000);   
           WG = split(wristG);
           RawWGX = str2double(WG{1});
           RawWGY = str2double(WG{2});
           RawWGZ = str2double(WG{3});
           if RawWGX >= 32768
              RawWGX = RawWGX - 65536;
           end
           if RawWGY >= 32768
              RawWGY = RawWGY - 65536;
           end
           if RawWGZ >= 32768
              RawWGZ = RawWGZ - 65536;
           end
           WGX = ((RawWGX*8.75)/1000);
           WGY = ((RawWGY*8.75)/1000);
           WGZ = ((RawWGZ*8.75)/1000);
           SG = split(shoulderG);
           RawSGX = str2double(SG{1});
           RawSGY = str2double(SG{2});
           RawSGZ = str2double(SG{3});
           if RawSGX >= 32768
              RawSGX = RawSGX - 65536;
           end
           if RawSGY >= 32768
              RawSGY = RawSGY - 65536;
           end
           if RawSGZ >= 32768
              RawSGZ = RawSGZ - 65536;
           end
           SGX = ((RawSGX*8.75)/1000);
           SGY = ((RawSGY*8.75)/1000);
           SGZ = ((RawSGZ*8.75)/1000); 
 %-----------GRAPHING------------------------------------------------------
           time(count) = count;
           dX1(count) = WAX;         
           dY1(count) = WAY;
           dZ1(count) = WAZ;
           dX2(count) = WGX;
           dY2(count) = WGY;
           dZ2(count) = WGZ;
           dX3(count) = SGX;
           dY3(count) = SGY;
           dZ3(count) = SGZ;
           dFlex(count) = Flex;
           %This is the magic code 
           set(plotGraphwax,'XData',time,'YData',dX1);
           set(plotGraphway,'XData',time,'YData',dY1);
           set(plotGraphwaz,'XData',time,'YData',dZ1);
           set(plotGraphwgx,'XData',time,'YData',dX2);
           set(plotGraphwgy,'XData',time,'YData',dY2);
           set(plotGraphwgz,'XData',time,'YData',dZ2);
           set(plotGraphsgx,'XData',time,'YData',dX3);
           set(plotGraphsgy,'XData',time,'YData',dY3);
           set(plotGraphsgz,'XData',time,'YData',dZ3);
           set(plotGraphFlex,'XData',time,'YData',dFlex);
           pause(delay);
           count = count + 1;  
           flushinput(t);%Flush input obtained while graphing to smoothen graphing
          else %If nothing arrived after 10 seconds of waiting for response
           pause(0.01);
           flushinput(t);
           timeout_counter = timeout_counter + 10;
           fprintf('Time passed without client response: %i seconds \n',timeout_counter);
           fprintf('Socket will close and connection will be lost after 60 seconds of no response\n');
           if timeout_counter >= 20 %Wait's 60 seconds to check if client is sending something, else close connection    
            fprintf('Connection lost\n');
            count = xmax + 2;%Exit counter
            is_connected = 0;%Is connected is now 0
           end
          end %End if statements
         end %While count<max ending, reset graphs and variables
        if is_connected == 1 
        clear time count dX1 dX2 dX3 dY1 dY2 dY3 dZ1 dZ2 dZ3 dFlex
        count = 1;
        time = 0;
        dX1 = 0;
        dY1 = 0;
        dZ1 = 0;
        dX2 = 0;
        dY2 = 0;
        dZ2 = 0;
        dX3 = 0;
        dY3 = 0;
        dZ3 = 0;
        dFlex = 0;
        figure(f1);
        cla reset %Reset all axis of the current figure
        %Set up Plot
        plotGraphwax = plot(time,dX1,'-r' );%every AnalogRead needs to be on its own Plotgraph
        hold on                             %hold on makes sure all of the channels are plotted
        plotGraphway = plot(time,dY1,'-b');
        plotGraphwaz = plot(time,dZ1,'-g' );
        title(plotTitle1,'FontSize',15);
        xlabel(xLabel,'FontSize',15);
        ylabel(yLabelA,'FontSize',15);
        legend(legendwax,legendway,legendwaz);
        xlim([xmin xmax]);
        ylim([yminA ymaxA]);
        grid(plotGrid); 
        figure(f2);
        cla reset %Reset all axis of the current figure
        %Set up Plot
        plotGraphwgx = plot(time,dX2,'-r' );%every AnalogRead needs to be on its own Plotgraph
        hold on                             %hold on makes sure all of the channels are plotted
        plotGraphwgy = plot(time,dY2,'-b');
        plotGraphwgz = plot(time,dZ2,'-g' );
        title(plotTitle2,'FontSize',15);
        xlabel(xLabel,'FontSize',15);
        ylabel(yLabelG,'FontSize',15);
        legend(legendwgx,legendwgy,legendwgz);
        xlim([xmin xmax]);
        ylim([yminG ymaxG]);
        grid(plotGrid); 
        figure(f3);
        cla reset %Reset all axis of the current figure
        plotGraphsgx = plot(time,dX3,'-r' );%every AnalogRead needs to be on its own Plotgraph
        hold on                             %hold on makes sure all of the channels are plotted
        plotGraphsgy = plot(time,dY3,'-b');
        plotGraphsgz = plot(time,dZ3,'-g' );
        title(plotTitle3,'FontSize',15);
        xlabel(xLabel,'FontSize',15);
        ylabel(yLabelG,'FontSize',15);
        legend(legendsgx,legendsgy,legendsgz);
        xlim([xmin xmax]);
        ylim([yminG ymaxG]);
        grid(plotGrid); 
        figure(f4);
        cla reset %Reset all axis of the current figure
        plotGraphFlex = plot(time,dFlex,'-r' );  
        title(plotTitle4,'FontSize',15);
        xlabel(xLabel,'FontSize',15);
        ylabel(yLabelFlex,'FontSize',15);
        legend(legendFlex);
        xlim([xmin xmax]);
        ylim([yminFlex ymaxFlex]);
        grid(plotGrid); 
        pause(0.06);%Wait
        flushinput(t); %Flush input
        end
    end %End of while Connected
    timeout_counter = 0;%Variable used to check connection timeout
    flushinput(t);%Flush socket
    fclose(t);%Close connection
end
fprintf('Program closed!\n');
flushinput(t);%Flush socket
fclose(t);%Close connection

function map = myMap(x, in_min,in_max,out_min,out_max)%Function used to map our raw flex reading to an angle

    map = (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
end

function y = constrain(rawFlex,x,min,max) %Used after we have mapped our raw value to an angle
if (rawFlex > max)%If our raw value is greater than our max angle, set angle to max angle
    y = max;
elseif (x < min) %If our mapped input is less than the minimun angle, set angle to min angle
    y = min;
elseif (max < x) %If our mapped input is greater than our max angle, set angle to max
    y = max;
else             %Keep the mapped input as it is
    y = x;
end

end