import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Api Model/project_list.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/mydownload_provider.dart';
import '../../network/provider/prpject_provider.dart';
import '../screens/template_edit.dart';

class MyDownloadScreen extends StatefulWidget {
  const MyDownloadScreen({super.key});

  @override
  State<MyDownloadScreen> createState() => _MyDownloadScreenState();
}

class _MyDownloadScreenState extends State<MyDownloadScreen> {
  late final ProjectProvider projectProvider;

  @override
  void initState() {
    super.initState();

    projectProvider = ProjectProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      projectProvider.fetchProject();
    });
  }

  @override
  void dispose() {
    projectProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectProvider>.value(
      value: projectProvider,
      child: Scaffold(
        appBar: AppBar(title: const Text('My Downloads')),
        body: Consumer<ProjectProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingPlans) {
              return const Center(child: CircularProgressIndicator());
            }

            final projectList = provider.plansData;

            if (projectList == null) {
              return Center(
                child: Text(provider.errorMessage ?? 'No projects found'),
              );
            }

            final projects = projectList.data;

            if (projects.isEmpty) {
              return const Center(child: Text('No projects found'));
            }

            return RefreshIndicator(
              onRefresh: provider.fetchProject,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];

                  return _projectCard(context, project);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _projectCard(BuildContext context, ProjectListModel project) {
    final key = project.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http://') || key.startsWith('https://')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditScreen(templateUid: project.uid),
          ),
        );
        debugPrint('Project UID: ${project.uid}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                        errorWidget: (context, url, error) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 35,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // NAME
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Text(
                project.name?.trim().isNotEmpty == true
                    ? project.name!
                    : 'Untitled Project',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
